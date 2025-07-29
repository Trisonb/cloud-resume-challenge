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
            document.getElementById('visitor-count').textContent = data.message;
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

document.addEventListener('DOMContentLoaded', function () {
    // Get the matrix-rain container
    const matrixRain = document.getElementById('matrix-rain');

    // Define the character set for the Matrix effect (letters, numbers, symbols)
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+-=[]{}|;:,.<>?~`';

    // Create 24 columns with 18 characters each
    for (let i = 0; i < 24; i++) {
        const column = document.createElement('div');
        column.className = 'column';

        // Generate a string of 18 characters, each in its own span
        let columnContent = '';
        for (let j = 0; j < 18; j++) {
            const span = document.createElement('span');
            span.className = 'char';
            span.textContent = chars.charAt(Math.floor(Math.random() * chars.length));
            column.appendChild(span);
            columnContent += span.outerHTML;
            if (j < 17) columnContent += '<br>'; // Add <br> except for last character
        }
        column.innerHTML = columnContent;

        // Set random animation duration between 8 and 15 seconds for fall
        const fallDuration = Math.random() * 7 + 8; // 8 to 15 seconds
        column.style.animationDuration = `${fallDuration}s`;

        // Set random animation delay between 0 and 4 seconds for fall
        const delay = Math.random() * 4;
        column.style.animationDelay = `${delay}s`;

        matrixRain.appendChild(column);
    }

    // Randomly change characters within a 5-second window
    function changeCharacter(charElement) {
        const randomDelay = Math.random() * 5000; // Random delay within 5 seconds
        setTimeout(() => {
            // Apply glitching class
            charElement.classList.add('glitching');
            setTimeout(() => {
                // Change to a new random character
                charElement.textContent = chars.charAt(Math.floor(Math.random() * chars.length));
                // Remove glitching class
                charElement.classList.remove('glitching');
                // Schedule next change
                changeCharacter(charElement);
            }, 200); // Glitch effect lasts 200ms
        }, randomDelay);
    }

    // Apply random character changes to all characters
    const charElements = document.querySelectorAll('.matrix-rain .char');
    charElements.forEach(charElement => {
        changeCharacter(charElement);
    });

    // Existing visitor counter code (if any) can go here
});