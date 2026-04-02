// /client/src/components/AIChatAssistant.jsx
import React, { useState, useRef, useEffect } from "react";
import axios from "axios";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { AI_SERVICE_URL } from "../apiConfig";

function AIChatAssistant() {
  const [messages, setMessages] = useState([]);
  const [inputMessage, setInputMessage] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const messagesEndRef = useRef(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const handleSendMessage = async (e) => {
    e.preventDefault();
    if (!inputMessage.trim()) return;

    const userMsg = { sender: "user", text: inputMessage };
    setMessages((m) => [...m, userMsg]);
    setInputMessage("");
    setLoading(true);
    setError(null);

    try {
      const res = await axios.post(`${AI_SERVICE_URL}/ai/chat`, {
        message: userMsg.text,
      });

      setMessages((m) => [
        ...m,
        { sender: "ai", text: res.data.response },
      ]);
    } catch {
      setError("AI response failed.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col h-[70vh] bg-white text-gray-800 rounded-lg shadow-lg p-6">
      <h2 className="text-2xl font-bold mb-4">AI Herbal Assistant</h2>

      <div className="flex-1 overflow-y-auto mb-4 bg-gray-50 p-3 rounded">
        {messages.map((msg, i) => (
          <div
            key={i}
            className={`mb-3 ${
              msg.sender === "user" ? "text-right" : "text-left"
            }`}
          >
            <div
              className={`inline-block p-3 rounded prose ${
                msg.sender === "user"
                  ? "bg-green-600 text-white"
                  : "bg-gray-200"
              }`}
            >
              <ReactMarkdown remarkPlugins={[remarkGfm]}>
                {msg.text}
              </ReactMarkdown>
            </div>
          </div>
        ))}

        {loading && <p>Thinking...</p>}
        <div ref={messagesEndRef} />
      </div>

      {error && <p className="text-red-600 mb-2">{error}</p>}

      <form onSubmit={handleSendMessage} className="flex">
        <input
          value={inputMessage}
          onChange={(e) => setInputMessage(e.target.value)}
          placeholder="Ask about plants..."
          className="flex-1 border p-3 rounded-l"
        />
        <button
          type="submit"
          disabled={loading}
          className="bg-green-600 text-white px-6 rounded-r"
        >
          Send
        </button>
      </form>
    </div>
  );
}

export default AIChatAssistant;
