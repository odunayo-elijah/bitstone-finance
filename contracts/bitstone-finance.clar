;; Title: BitStone Finance - Institutional Bitcoin Collateral Protocol
;;
;; Summary:
;; A sophisticated decentralized lending platform that transforms Bitcoin holdings 
;; into productive capital through secure collateralized loans, featuring advanced 
;; risk management algorithms and institutional-grade liquidation protection.

;;                               SYSTEM CONSTANTS                               

(define-constant CONTRACT-OWNER tx-sender)

;; Protocol Error Codes
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-NOT-INITIALIZED (err u104))
(define-constant ERR-LOAN-NOT-FOUND (err u105))
(define-constant ERR-LOAN-INACTIVE (err u106))
(define-constant ERR-INVALID-PRICE-FEED (err u108))

;;                              PROTOCOL VARIABLES                              

(define-data-var protocol-active bool false)
(define-data-var minimum-collateral-ratio uint u150) ;; 150% minimum collateralization
(define-data-var liquidation-threshold uint u120) ;; 120% liquidation trigger
(define-data-var base-interest-rate uint u5) ;; 5% base annual rate
(define-data-var total-value-locked uint u0) ;; Total BTC locked in protocol
(define-data-var loan-counter uint u0) ;; Global loan ID counter

;;                                 DATA MAPS                                    

;; Core loan data structure
(define-map loan-registry
  { loan-id: uint }
  {
    borrower: principal,
    collateral-amount: uint,
    borrowed-amount: uint,
    interest-rate: uint,
    creation-block: uint,
    last-update: uint,
    status: (string-ascii 20),
  }
)

;; Asset price oracle (simplified to BTC only)
(define-map asset-prices
  { asset: (string-ascii 3) }
  {
    price: uint,
    last-update: uint,
  }
)

;;                              PRIVATE FUNCTIONS                               

;; Calculate current collateralization ratio
(define-private (get-collateral-ratio
    (collateral-amount uint)
    (loan-amount uint)
    (btc-price uint)
  )
  (let ((collateral-value (* collateral-amount btc-price)))
    (if (> loan-amount u0)
      (/ (* collateral-value u100) loan-amount)
      u0
    )
  )
)

;; Compute accrued interest based on blocks elapsed
(define-private (calculate-accrued-interest
    (principal-amount uint)
    (interest-rate uint)
    (blocks-elapsed uint)
  )
  (let (
      (daily-rate (/ interest-rate u365))
      (block-rate (/ daily-rate u144)) ;; Assuming ~144 blocks per day
    )
    (/ (* (* principal-amount block-rate) blocks-elapsed) u10000)
  )
)

;; Check if loan requires liquidation
(define-private (requires-liquidation (loan-id uint))
  (match (map-get? loan-registry { loan-id: loan-id })
    loan-data (match (map-get? asset-prices { asset: "BTC" })
      btc-data (let ((current-ratio (get-collateral-ratio (get collateral-amount loan-data)
          (get borrowed-amount loan-data) (get price btc-data)
        )))
        (<= current-ratio (var-get liquidation-threshold))
      )
      false
    )
    false
  )
)

;;                               PUBLIC FUNCTIONS                               

;;                            PROTOCOL MANAGEMENT                              

;; Initialize the BitStone Finance protocol
(define-public (initialize-protocol)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (not (var-get protocol-active)) (err u103)) ;; ERR-ALREADY-INITIALIZED
    (var-set protocol-active true)
    (ok "BitStone Finance Protocol Initialized")
  )
)

;; Update minimum collateral requirements
(define-public (set-collateral-ratio (new-ratio uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (>= new-ratio u110) ERR-INVALID-AMOUNT)
    (var-set minimum-collateral-ratio new-ratio)
    (ok true)
  )
)

;; Update asset price feeds (BTC only)
(define-public (update-btc-price (price uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (> price u0) ERR-INVALID-PRICE-FEED)
    (map-set asset-prices { asset: "BTC" } {
      price: price,
      last-update: stacks-block-height,
    })
    (ok true)
  )
)

;;                             LENDING OPERATIONS                              

;; Create new collateralized loan
(define-public (create-loan
    (collateral-amount uint)
    (requested-amount uint)
  )
  (let (
      (btc-price-data (unwrap! (map-get? asset-prices { asset: "BTC" }) ERR-INVALID-PRICE-FEED))
      (btc-price (get price btc-price-data))
      (collateral-value (* collateral-amount btc-price))
      (required-collateral (* requested-amount (var-get minimum-collateral-ratio)))
      (new-loan-id (+ (var-get loan-counter) u1))
    )
    (begin
      (asserts! (var-get protocol-active) ERR-NOT-INITIALIZED)
      (asserts! (> collateral-amount u0) ERR-INVALID-AMOUNT)
      (asserts! (> requested-amount u0) ERR-INVALID-AMOUNT)
      (asserts! (>= (* collateral-value u100) required-collateral)
        ERR-INSUFFICIENT-COLLATERAL
      )

      ;; Create loan record
      (map-set loan-registry { loan-id: new-loan-id } {
        borrower: tx-sender,
        collateral-amount: collateral-amount,
        borrowed-amount: requested-amount,
        interest-rate: (var-get base-interest-rate),
        creation-block: stacks-block-height,
        last-update: stacks-block-height,
        status: "active",
      })

      ;; Update protocol metrics
      (var-set total-value-locked
        (+ (var-get total-value-locked) collateral-amount)
      )
      (var-set loan-counter new-loan-id)

      (ok new-loan-id)
    )
  )
)

;; Repay loan and reclaim collateral
(define-public (repay-loan
    (loan-id uint)
    (payment-amount uint)
  )
  (let (
      (loan-data (unwrap! (map-get? loan-registry { loan-id: loan-id }) ERR-LOAN-NOT-FOUND))
      (blocks-elapsed (- stacks-block-height (get last-update loan-data)))
      (accrued-interest (calculate-accrued-interest (get borrowed-amount loan-data)
        (get interest-rate loan-data) blocks-elapsed
      ))
      (total-due (+ (get borrowed-amount loan-data) accrued-interest))
    )
    (begin
      (asserts! (is-eq (get status loan-data) "active") ERR-LOAN-INACTIVE)
      (asserts! (is-eq (get borrower loan-data) tx-sender) ERR-UNAUTHORIZED)
      (asserts! (>= payment-amount total-due) ERR-INVALID-AMOUNT)

      ;; Mark loan as repaid
      (map-set loan-registry { loan-id: loan-id }
        (merge loan-data {
          status: "repaid",
          last-update: stacks-block-height,
        })
      )

      ;; Release collateral
      (var-set total-value-locked
        (- (var-get total-value-locked) (get collateral-amount loan-data))
      )

      (ok {
        collateral-released: (get collateral-amount loan-data),
        interest-paid: accrued-interest,
      })
    )
  )
)

;; Liquidate undercollateralized positions
(define-public (liquidate-loan (loan-id uint))
  (let ((loan-data (unwrap! (map-get? loan-registry { loan-id: loan-id }) ERR-LOAN-NOT-FOUND)))
    (begin
      (asserts! (is-eq (get status loan-data) "active") ERR-LOAN-INACTIVE)
      (asserts! (requires-liquidation loan-id) ERR-INSUFFICIENT-COLLATERAL)

      ;; Execute liquidation
      (map-set loan-registry { loan-id: loan-id }
        (merge loan-data { status: "liquidated" })
      )
      (var-set total-value-locked
        (- (var-get total-value-locked) (get collateral-amount loan-data))
      )
      (ok true)
    )
  )
)

;;                              READ-ONLY FUNCTIONS                             

;; Get detailed loan information
(define-read-only (get-loan-info (loan-id uint))
  (match (map-get? loan-registry { loan-id: loan-id })
    loan-data (let (
        (blocks-elapsed (- stacks-block-height (get last-update loan-data)))
        (accrued-interest (calculate-accrued-interest (get borrowed-amount loan-data)
          (get interest-rate loan-data) blocks-elapsed
        ))
      )
      (ok (merge loan-data { current-interest-due: accrued-interest }))
    )
    ERR-LOAN-NOT-FOUND
  )
)

;; Get current BTC price
(define-read-only (get-btc-price)
  (map-get? asset-prices { asset: "BTC" })
)

;; Get protocol statistics
(define-read-only (get-protocol-stats)
  {
    protocol-active: (var-get protocol-active),
    total-value-locked: (var-get total-value-locked),
    total-loans-issued: (var-get loan-counter),
    minimum-collateral-ratio: (var-get minimum-collateral-ratio),
    liquidation-threshold: (var-get liquidation-threshold),
    base-interest-rate: (var-get base-interest-rate),
  }
)
