// Configuration
const CONFIG = {
    EARLY_BIRD_LIMIT: 50, // First 50 users get early access
    SUPABASE_URL: '', // Optional: for analytics tracking
    SUPABASE_ANON_KEY: '' // Optional: for analytics tracking
};

// State management
let currentSignupCount = 0;

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    initializeScarcityCounter();
    setupFormHandler();
    initializePhoneMockup();
});

/**
 * Initialize iPhone mockup screen cycling
 */
function initializePhoneMockup() {
    const screens = document.querySelectorAll('.screen-content');
    let currentScreen = 0;

    // Cycle through screens every 3 seconds
    setInterval(() => {
        screens[currentScreen].classList.remove('active');
        currentScreen = (currentScreen + 1) % screens.length;
        screens[currentScreen].classList.add('active');
    }, 3000);
}


/**
 * Initialize the scarcity counter
 * In production, this should fetch the real count from ConvertKit or Supabase
 */
async function initializeScarcityCounter() {
    try {
        // TODO: In production, fetch real count from ConvertKit API
        // For now, we'll use localStorage to simulate persistence
        const storedCount = localStorage.getItem('logaby_signup_count');
        currentSignupCount = storedCount ? parseInt(storedCount) : 0;

        updateScarcityUI();
    } catch (error) {
        console.error('Error initializing counter:', error);
    }
}

/**
 * Update the scarcity badge UI
 */
function updateScarcityUI() {
    const spotsLeft = CONFIG.EARLY_BIRD_LIMIT - currentSignupCount;
    const scarcityText = document.getElementById('scarcityText');
    const scarcityBadge = document.getElementById('scarcityBadge');

    if (spotsLeft > 0) {
        scarcityText.innerHTML = `🔥 Only <strong>${spotsLeft}</strong> early access spots left!`;
        scarcityBadge.style.display = 'inline-flex';
    } else {
        scarcityText.innerHTML = `Join the waitlist for launch updates`;
        scarcityBadge.style.background = 'linear-gradient(135deg, #E8E0F0 0%, #D0C4E0 100%)';
        scarcityBadge.style.borderColor = '#9B7FB8';
    }
}

/**
 * Setup form submission handler
 */
function setupFormHandler() {
    const form = document.getElementById('waitlistForm');
    const emailInput = document.getElementById('emailInput');
    const submitBtn = document.getElementById('submitBtn');
    const formMessage = document.getElementById('formMessage');

    form.addEventListener('submit', async (e) => {
        e.preventDefault();

        const email = emailInput.value.trim();

        if (!email || !isValidEmail(email)) {
            showMessage('Please enter a valid email address', 'error');
            return;
        }

        // Disable form during submission
        submitBtn.disabled = true;
        submitBtn.textContent = 'Joining...';

        try {
            await subscribeToWaitlist(email);
        } catch (error) {
            console.error('Subscription error:', error);
            showMessage('Something went wrong. Please try again.', 'error');
        } finally {
            submitBtn.disabled = false;
            submitBtn.textContent = 'Get Early Access';
        }
    });
}

/**
 * Subscribe email to Brevo
 * Subscribe email to waitlist via serverless function
 */
async function subscribeToWaitlist(email) {
    const formMessage = document.getElementById('formMessage');

    try {
        // Increment signup count
        currentSignupCount++;
        const signupNumber = currentSignupCount;
        const isEarlyBird = signupNumber <= CONFIG.EARLY_BIRD_LIMIT;

        // Call our serverless function
        const response = await fetch('/api/subscribe', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                email: email,
                signupNumber: signupNumber,
                isEarlyBird: isEarlyBird
            })
        });

        const data = await response.json();

        if (response.ok && data.success) {
            // Success!
            localStorage.setItem('logaby_signup_count', currentSignupCount.toString());
            updateScarcityUI();

            // Trigger confetti celebration!
            if (typeof confetti !== 'undefined') {
                confetti({
                    particleCount: 100,
                    spread: 70,
                    origin: { y: 0.6 }
                });
            }

            // Show success message
            if (data.duplicate) {
                showMessage(
                    `✅ You're already on the waitlist! Check your email for updates.`,
                    'success'
                );
            } else {
                showMessage(
                    `🎉 You're in! Welcome to the Logaby waitlist. Check your email for updates!`,
                    'success'
                );
            }

            // Clear form
            document.getElementById('emailInput').value = '';

            // Optional: Track in Supabase for analytics
            if (CONFIG.SUPABASE_URL && CONFIG.SUPABASE_ANON_KEY) {
                trackInSupabase(email, signupNumber, data.id);
            }

        } else {
            // Handle errors
            showMessage(`Error: ${data.error || 'Unable to subscribe. Please try again.'}`, 'error');
        }

    } catch (error) {
        console.error('Subscription error:', error);
        showMessage('Network error. Please check your connection and try again.', 'error');
    }
}

/**
 * Optional: Track signup in Supabase for analytics
 */
async function trackInSupabase(email, signupNumber, convertkitId) {
    try {
        const response = await fetch(`${CONFIG.SUPABASE_URL}/rest/v1/waitlist`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'apikey': CONFIG.SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${CONFIG.SUPABASE_ANON_KEY}`
            },
            body: JSON.stringify({
                email: email,
                signup_number: signupNumber,
                convertkit_subscriber_id: convertkitId,
                source: getUTMSource()
            })
        });

        if (!response.ok) {
            console.warn('Supabase tracking failed (non-critical)');
        }
    } catch (error) {
        console.warn('Supabase tracking error (non-critical):', error);
    }
}

/**
 * Get UTM source from URL parameters
 */
function getUTMSource() {
    const params = new URLSearchParams(window.location.search);
    return params.get('utm_source') || 'direct';
}

/**
 * Validate email format
 */
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

/**
 * Show form message
 */
function showMessage(message, type) {
    const formMessage = document.getElementById('formMessage');
    formMessage.textContent = message;
    formMessage.className = `form-message ${type}`;
    formMessage.style.display = 'block'; // Make the message visible
    formMessage.style.marginTop = '16px'; // Add spacing

    // Auto-hide success messages after 10 seconds
    if (type === 'success') {
        setTimeout(() => {
            formMessage.style.display = 'none';
        }, 10000);
    }
}
