;; Obsidian Vortex Marketplace - Advanced Decentralized E-commerce Platform
;; A comprehensive smart contract for decentralized commerce operations
;; Built with Clarinet for Stacks blockchain

;; Contract Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INVALID-PRODUCT (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-ORDER-NOT-FOUND (err u103))
(define-constant ERR-INVALID-STATUS (err u104))
(define-constant ERR-PAYMENT-FAILED (err u105))
(define-constant ERR-VENDOR-NOT-FOUND (err u106))
(define-constant ERR-REVIEW-NOT-FOUND (err u107))
(define-constant ERR-INVALID-QUANTITY (err u108))
(define-constant ERR-PRODUCT-UNAVAILABLE (err u109))
(define-constant ERR-DISPUTE-EXISTS (err u110))

;; Platform Configuration
(define-constant PLATFORM-FEE-PERCENTAGE u250) ;; 2.5%
(define-constant MAX-REVIEW-RATING u5)
(define-constant MIN-VENDOR-STAKE u1000000) ;; 1 STX minimum stake
(define-constant DISPUTE-RESOLUTION-PERIOD u14400) ;; ~10 days in blocks

;; Data Variables
(define-data-var next-product-id uint u1)
(define-data-var next-order-id uint u1)
(define-data-var next-vendor-id uint u1)
(define-data-var next-review-id uint u1)
(define-data-var platform-treasury uint u0)
(define-data-var contract-paused bool false)

;; Product Categories Enum
(define-constant CATEGORY-ELECTRONICS u1)
(define-constant CATEGORY-FASHION u2)
(define-constant CATEGORY-HOME-GARDEN u3)
(define-constant CATEGORY-BOOKS u4)
(define-constant CATEGORY-SPORTS u5)
(define-constant CATEGORY-BEAUTY u6)
(define-constant CATEGORY-AUTOMOTIVE u7)
(define-constant CATEGORY-DIGITAL u8)

;; Order Status Enum
(define-constant STATUS-PENDING u1)
(define-constant STATUS-CONFIRMED u2)
(define-constant STATUS-PROCESSING u3)
(define-constant STATUS-SHIPPED u4)
(define-constant STATUS-DELIVERED u5)
(define-constant STATUS-CANCELLED u6)
(define-constant STATUS-REFUNDED u7)
(define-constant STATUS-DISPUTED u8)

;; Vendor Status Enum
(define-constant VENDOR-ACTIVE u1)
(define-constant VENDOR-SUSPENDED u2)
(define-constant VENDOR-BANNED u3)

;; Data Maps

;; Vendor Management
(define-map astral-vendors
    { vendor-id: uint }
    {
        owner: principal,
        business-name: (string-ascii 100),
        contact-info: (string-ascii 200),
        reputation-score: uint,
        total-sales: uint,
        stake-amount: uint,
        status: uint,
        registration-block: uint,
        kyc-verified: bool
    }
)

;; Product Catalog
(define-map quantum-products
    { product-id: uint }
    {
        vendor-id: uint,
        name: (string-ascii 100),
        description: (string-ascii 500),
        category: uint,
        price: uint,
        quantity-available: uint,
        is-digital: bool,
        metadata-uri: (optional (string-ascii 200)),
        creation-block: uint,
        total-sold: uint,
        average-rating: uint,
        review-count: uint,
        is-active: bool
    }
)

;; Order Management
(define-map nebula-orders
    { order-id: uint }
    {
        buyer: principal,
        vendor-id: uint,
        product-id: uint,
        quantity: uint,
        total-amount: uint,
        platform-fee: uint,
        vendor-amount: uint,
        status: uint,
        shipping-address: (string-ascii 300),
        tracking-info: (optional (string-ascii 100)),
        creation-block: uint,
        completion-block: (optional uint),
        payment-escrow: uint
    }
)

;; Review System
(define-map stellar-reviews
    { review-id: uint }
    {
        order-id: uint,
        reviewer: principal,
        product-id: uint,
        vendor-id: uint,
        rating: uint,
        comment: (string-ascii 500),
        verified-purchase: bool,
        helpful-count: uint,
        creation-block: uint
    }
)

;; Shopping Cart System
(define-map cosmic-carts
    { buyer: principal, product-id: uint }
    {
        quantity: uint,
        added-block: uint
    }
)

;; Dispute Resolution
(define-map plasma-disputes
    { order-id: uint }
    {
        initiator: principal,
        reason: (string-ascii 300),
        evidence-uri: (optional (string-ascii 200)),
        status: uint,
        resolution: (optional (string-ascii 300)),
        arbitrator: (optional principal),
        creation-block: uint,
        resolution-block: (optional uint)
    }
)

;; Vendor Performance Tracking
(define-map velocity-metrics
    { vendor-id: uint, metric-type: (string-ascii 20) }
    {
        value: uint,
        last-updated: uint
    }
)

;; Loyalty Program
(define-map aurora-loyalty
    { user: principal }
    {
        points-balance: uint,
        tier-level: uint,
        total-spent: uint,
        referral-count: uint,
        last-activity: uint
    }
)

;; Inventory Tracking
(define-map inventory-ledger
    { product-id: uint, batch-id: uint }
    {
        quantity: uint,
        cost-basis: uint,
        expiry-block: (optional uint),
        supplier-info: (string-ascii 100)
    }
)

;; Private Functions

;; Calculate platform fee based on order amount
(define-private (calculate-platform-fee (amount uint))
    (/ (* amount PLATFORM-FEE-PERCENTAGE) u10000)
)

;; Validate product category
(define-private (is-valid-category (category uint))
    (and (>= category u1) (<= category u8))
)

;; Validate order status transition
(define-private (is-valid-status-transition (current-status uint) (new-status uint))
    (or
        (and (is-eq current-status STATUS-PENDING) (is-eq new-status STATUS-CONFIRMED))
        (and (is-eq current-status STATUS-CONFIRMED) (is-eq new-status STATUS-PROCESSING))
        (and (is-eq current-status STATUS-PROCESSING) (is-eq new-status STATUS-SHIPPED))
        (and (is-eq current-status STATUS-SHIPPED) (is-eq new-status STATUS-DELIVERED))
        (and (<= current-status STATUS-SHIPPED) (is-eq new-status STATUS-CANCELLED))
        (and (<= current-status STATUS-DELIVERED) (is-eq new-status STATUS-REFUNDED))
        (and (<= current-status STATUS-SHIPPED) (is-eq new-status STATUS-DISPUTED))
    )
)