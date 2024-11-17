module DecentralizedInsuranceSystem::DeFiInsurance {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;

    /// Error codes
    const E_INSUFFICIENT_COVERAGE: u64 = 1;
    const E_POLICY_NOT_FOUND: u64 = 2;
    const E_POLICY_EXPIRED: u64 = 3;

    /// Insurance policy struct
    struct Policy has store, key {
        coverage_amount: u64,    // Amount of coverage in AptosCoin
        premium_paid: u64,       // Premium amount paid
        expiration_time: u64,    // Timestamp when policy expires
        is_active: bool,         // Policy status
    }

    /// Create a new insurance policy
    public fun create_policy(
        policyholder: &signer,
        coverage_amount: u64,
        duration_seconds: u64
    ) {
        let premium = calculate_premium(coverage_amount);
        
        // Transfer premium payment
        let premium_payment = coin::withdraw<AptosCoin>(policyholder, premium);
        // coin::deposit<AptosCoin>(@mymodule, premium_payment);

        // Create and store policy
        let policy = Policy {
            coverage_amount,
            premium_paid: premium,
            expiration_time: timestamp::now_seconds() + duration_seconds,
            is_active: true,
        };
        move_to(policyholder, policy);
    }

    /// Process an insurance claim
    public fun process_claim(
        claimer: &signer,
        claim_amount: u64
    ) acquires Policy {
        let claimer_addr = signer::address_of(claimer);
        assert!(exists<Policy>(claimer_addr), E_POLICY_NOT_FOUND);
        
        let policy = borrow_global_mut<Policy>(claimer_addr);
        assert!(policy.is_active, E_POLICY_NOT_FOUND);
        assert!(timestamp::now_seconds() < policy.expiration_time, E_POLICY_EXPIRED);
        assert!(claim_amount <= policy.coverage_amount, E_INSUFFICIENT_COVERAGE);

        // Process the claim payment
        let claim_payment = coin::withdraw<AptosCoin>(@mymodule, claim_amount);
        // coin::deposit<AptosCoin>(claimer_addr, claim_payment);
        
        // Update policy status
        policy.is_active = false;
    }

    /// Helper function to calculate premium (simplified version)
    fun calculate_premium(coverage_amount: u64): u64 {
        // Simple premium calculation: 5% of coverage amount
        coverage_amount / 20
    }
}