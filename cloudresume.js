let callCount = 0;

const API = "https://bqh8vbfanf.execute-api.us-east-1.amazonaws.com/Dev/visitor?nocache=" + Date.now();

async function incrementVisitorCount() {
    callCount++;
    console.log(`incrementVisitorCount called ${callCount} times`);

    const userData = { user: 'visitor' };
    try {
        console.log("Sending POST request to API:", API);
        const response = await fetch(API, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Cache-Control': 'no-cache',
                'Custom-No-Cache': Date.now().toString(),
            },
            body: JSON.stringify(userData),
        });

        console.log("Response status:", response.status);
        if (!response.ok) {
            const errorText = await response.text();
            throw new Error(`HTTP error! status: ${response.status}, body: ${errorText}`);
        }

        const data = await response.json();
        console.log("Response data:", data);
        if (data && data.message) {
            document.getElementById('visitor-count').textContent = data.message;
        } else {
            throw new Error('Invalid response format: missing message field');
        }
    } catch (error) {
        console.error('Error fetching visitor count:', error);
        document.getElementById('visitor-count').textContent = 'Error fetching visit count';
    }
}

window.onload = function () {
    console.log('window.onload triggered');
    incrementVisitorCount();
};