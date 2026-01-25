// Vercel Serverless Function for Brevo Email Subscription
export default async function handler(req, res) {
    // Only allow POST requests
    if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
    }

    const { email, signupNumber, isEarlyBird } = req.body;

    // Validate email
    if (!email || !email.includes('@')) {
        return res.status(400).json({ error: 'Invalid email address' });
    }

    // Get Brevo credentials from environment variables
    const BREVO_API_KEY = process.env.BREVO_API_KEY;
    const BREVO_LIST_ID = process.env.BREVO_LIST_ID;

    if (!BREVO_API_KEY || !BREVO_LIST_ID) {
        console.error('Brevo credentials not configured');
        return res.status(500).json({ error: 'Server configuration error' });
    }

    try {
        // Call Brevo API
        const response = await fetch('https://api.brevo.com/v3/contacts', {
            method: 'POST',
            headers: {
                'accept': 'application/json',
                'api-key': BREVO_API_KEY,
                'content-type': 'application/json'
            },
            body: JSON.stringify({
                email: email,
                listIds: [parseInt(BREVO_LIST_ID)],
                attributes: {
                    SIGNUP_NUMBER: signupNumber || 0,
                    EARLY_BIRD: isEarlyBird || false,
                    SOURCE: 'Landing Page'
                },
                updateEnabled: false
            })
        });

        const data = await response.json();

        if (response.ok || response.status === 201) {
            return res.status(200).json({
                success: true,
                message: 'Successfully subscribed',
                id: data.id
            });
        } else if (data.code === 'duplicate_parameter') {
            // Already subscribed - treat as success
            return res.status(200).json({
                success: true,
                message: 'Already subscribed',
                duplicate: true
            });
        } else {
            console.error('Brevo API error:', data);
            console.error('Response status:', response.status);
            return res.status(400).json({
                error: data.message || 'Failed to subscribe',
                code: data.code,
                status: response.status
            });
        }
    } catch (error) {
        console.error('Server error:', error);
        return res.status(500).json({ error: 'Internal server error', details: error.message });
    }
}
