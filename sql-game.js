function handleInput() {
    const userInput = document.getElementById('userInput').value.trim();
    const chatBox = document.getElementById('chatBox');

    if (!userInput) return; // Ignore empty input

    // Log attempt to console with timestamp
    console.log(`[${new Date().toISOString()}] User input: ${userInput}`);

    // Append user message to chat box
    const userMessage = document.createElement('div');
    userMessage.className = 'user-message';
    userMessage.textContent = `You: ${userInput}`;
    chatBox.appendChild(userMessage);

    // Check for SQL injection patterns
    const sqlPatterns = [
        { pattern: /(drop\s+(table|database))/i, roast: "Whoa, trying to DROP TABLE? That's so 90s, even my grandma's database is safe from that! 😂😜" },
        { pattern: /(select\s+\*)/i, roast: "SELECT *? Really? You think you can sneak that past me? Try harder 😜" },
        { pattern: /(union\s+(all|select))/i, roast: "UNION attack? Bro, I saw that coming from a mile away. Go back to SQL 101! 😂" },
        { pattern: /(or|and)\s+['"]?1['"]?\s*=\s*['"]?1['"]?/i, roast: "OR '1'='1'? That's the oldest trick in the book! My firewall laughs at you! 😂😂" },
        { pattern: /(--|\/\*|\*\/)/i, roast: "Comments like -- or /*? You're not even trying to hide it! Step up your game! 🥱" },
        { pattern: /(delete|update|insert)\s+/i, roast: "Trying to DELETE, UPDATE, or INSERT? Nice try, but my defenses are tighter than a vault! 😝" }
    ];

    let botResponse = "Bot: Hmm, that doesn't look like a SQL injection 🤨 Try something spicier!";
    for (const { pattern, roast } of sqlPatterns) {
        if (pattern.test(userInput)) {
            botResponse = `Bot: ${roast}`;
            break;
        }
    }

    // Append bot response to chat box
    const botMessage = document.createElement('div');
    botMessage.className = 'bot-message';
    botMessage.textContent = botResponse;
    chatBox.appendChild(botMessage);

    // Clear input field
    document.getElementById('userInput').value = '';

    // Scroll to bottom of chat box
    chatBox.scrollTop = chatBox.scrollHeight;
}

// Add CSS classes for message styling
const style = document.createElement('style');
style.textContent = `
    .chat-container { margin-top: 1rem; }
    .chat-box { 
        height: 300px; 
        overflow-y: scroll; 
        background-color: rgba(0, 0, 0, 0.8); 
        border: 1px solid #00FF00; 
        padding: 10px; 
        margin-bottom: 10px; 
        font-family: 'VT323', monospace; 
        color: #00FF00;
    }
    .user-message { color: #00FF00; margin: 5px 0; }
    .bot-message { color: #FF4500; margin: 5px 0; }
    input[type="text"] { 
        background-color: #000; 
        color: #00FF00; 
        border: 1px solid #00FF00; 
        font-family: 'VT323', monospace; 
        font-size: 16pt; 
    }
    button { 
        background-color: #00FF00; 
        color: #000; 
        border: none; 
        font-family: 'VT323', monospace; 
        font-size: 16pt; 
        cursor: pointer; 
    }
    button:hover { background-color: #00CC00; }
`;
document.head.appendChild(style);