let callCount = 0;
const API = "https://6wo09eb1qh.execute-api.us-east-1.amazonaws.com/Dev/visitor";

async function incrementVisitorCount(retryCount = 0, maxRetries = 3) {
    callCount++;
    console.log(`incrementVisitorCount called ${callCount} times`);

    const userData = { user: 'visitor' };
    try {
        console.log("Sending POST request to API:", API);
        const response = await fetch(API + '?nocache=' + Date.now(), {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Cache-Control': 'no-cache'
            },
            mode: 'cors',
            body: JSON.stringify(userData)
        });

        console.log("Response status:", response.status);
        if (!response.ok) {
            const errorText = await response.text();
            throw new Error(`HTTP error! status: ${response.status}, body: ${errorText}`);
        }

        const data = await response.json();
        console.log("Response data:", data);
        if (data && data.message) {
            const count = data.message.match(/\d+/) ? data.message.match(/\d+/)[0] : 'Error';
            document.getElementById('visitor-count').textContent = count;
        } else {
            throw new Error('Invalid response format: missing message field');
        }
    } catch (error) {
        console.error('Error fetching visitor count:', error);
        document.getElementById('visitor-count').textContent = 'Error fetching visit count';
        if (retryCount < maxRetries && error.message.includes('Failed to fetch')) {
            console.log(`Retrying (${retryCount + 1}/${maxRetries}) in 5 seconds...`);
            setTimeout(() => incrementVisitorCount(retryCount + 1, maxRetries), 5000);
        }
    }
}

window.onload = function () {
    console.log('window.onload triggered');
    incrementVisitorCount();
};