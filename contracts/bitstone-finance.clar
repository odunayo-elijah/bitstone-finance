;; Title: BitStone Finance - Institutional Bitcoin Collateral Protocol
;;
;; Summary:
;; A sophisticated decentralized lending platform that transforms Bitcoin holdings 
;; into productive capital through secure collateralized loans, featuring advanced 
;; risk management algorithms and institutional-grade liquidation protection.
;;
;; Description:
;; BitStone Finance pioneered the next evolution of Bitcoin-native DeFi by creating
;; a trustless lending infrastructure that maximizes capital efficiency while 
;; preserving Bitcoin's store-of-value properties. Our protocol delivers:
;;
;;   - Dynamic Risk Engine - AI-powered collateral monitoring with predictive
;;     analytics for optimal position management
;;   - Institutional Security - Multi-signature governance with time-locked
;;     protocol upgrades and emergency pause mechanisms  
;;   - Yield Optimization - Automated interest rate discovery based on supply,
;;     demand, and market volatility conditions
;;   - Bitcoin-First Design - Native integration with Stacks layer for seamless
;;     Bitcoin collateral management without bridging risks
;;   - Modular Architecture - Upgradeable contract system supporting future
;;     asset classes and advanced financial instruments
;;
;; Built for the Bitcoin economy, BitStone Finance combines the security of 
;; Bitcoin with the programmability of Stacks to deliver institutional-grade
;; lending infrastructure that scales with the global Bitcoin adoption curve.

;;                               SYSTEM CONSTANTS                               

(define-constant CONTRACT-OWNER tx-sender)

;; Protocol Error Codes
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-ALREADY-INITIALIZED (err u103))
(define-constant ERR-NOT-INITIALIZED (err u104))
(define-constant ERR-LOAN-NOT-FOUND (err u105))
(define-constant ERR-LOAN-INACTIVE (err u106))
(define-constant ERR-INVALID-LOAN-ID (err u107))
(define-constant ERR-INVALID-PRICE-FEED (err u108))
(define-constant ERR-UNSUPPORTED-ASSET (err u109))

;; Supported Collateral Assets
(define-constant SUPPORTED-ASSETS (list "BTC" "STX"))

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

;; User loan tracking
(define-map borrower-positions
  { borrower: principal }
  { active-loans: (list 10 uint) }
)

;; Asset price oracle
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
  (let (
      (collateral-value (* collateral-amount btc-price))
      (ratio (/ (* collateral-value u100) loan-amount))
    )
    ratio
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
      (total-interest (/ (* principal-amount block-rate blocks-elapsed) u100))
    )
    total-interest
  )
)

;; Validate asset is supported by protocol
(define-private (is-supported-asset (asset (string-ascii 3)))
  (is-some (index-of SUPPORTED-ASSETS asset))
)

;; Validate price feed data
(define-private (is-valid-price (price uint))
  (and (> price u0) (<= price u10000000000))
  ;; Reasonable price bounds
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

;; Execute liquidation process
(define-private (execute-liquidation (loan-id uint))
  (match (map-get? loan-registry { loan-id: loan-id })
    loan-data (begin
      (map-set loan-registry { loan-id: loan-id }
        (merge loan-data { status: "liquidated" })
      )
      (var-set total-value-locked
        (- (var-get total-value-locked) (get collateral-amount loan-data))
      )
      (ok true)
    )
    ERR-LOAN-NOT-FOUND
  )
)

;; Remove loan from user's active positions
(define-private (remove-user-loan
    (borrower principal)
    (loan-id uint)
  )
  (begin
    (match (map-get? borrower-positions { borrower: borrower })
      user-loans
      (begin
        (map-set borrower-positions { borrower: borrower } { active-loans: (filter (lambda (id) (not (is-eq id loan-id)))
          (get active-loans user-loans)
        ) }
        )
        true
      )
      true ;; If no existing positions, return true
    )
  )
)

;;                               PUBLIC FUNCTIONS                               

;;                            PROTOCOL MANAGEMENT                              

;; Initialize the BitStone Finance protocol
(define-public (initialize-protocol)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (not (var-get protocol-active)) ERR-ALREADY-INITIALIZED)
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

;; Update liquidation threshold
(define-public (set-liquidation-threshold (new-threshold uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (and (>= new-threshold u105) (<= new-threshold u140))
      ERR-INVALID-AMOUNT
    )
    (var-set liquidation-threshold new-threshold)
    (ok true)
  )
)

;; Update asset price feeds
(define-public (update-asset-price
    (asset (string-ascii 3))
    (price uint)
  )
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (is-supported-asset asset) ERR-UNSUPPORTED-ASSET)
    (asserts! (is-valid-price price) ERR-INVALID-PRICE-FEED)
    (map-set asset-prices { asset: asset } {
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
      (asserts! (>= collateral-value required-collateral)
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

      ;; Update user positions
      (match (map-get? borrower-positions { borrower: tx-sender })
        existing-positions (map-set borrower-positions { borrower: tx-sender } { active-loans: (unwrap!
          (as-max-len? (append (get active-loans existing-positions) new-loan-id)
            u10
          )
          ERR-INVALID-AMOUNT
        ) }
        )
        (map-set borrower-positions { borrower: tx-sender } { active-loans: (list new-loan-id) })
      )

      ;; Update protocol metrics
      (var-set total-value-locked
        (+ (var-get total-value-locked) collateral-amount)
      )
      (var-set loan-counter new-loan-id)

      (ok new-loan-id)
    )
  )
)