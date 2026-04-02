import React, { useState, useEffect } from "react";
import axios from "axios";
import { useNavigate } from "react-router-dom";
import { Eye, EyeOff } from "lucide-react";
import { AUTH_SERVICE_URL } from "../apiConfig";

// const AUTH_URL = import.meta.env.VITE_AUTH_API;

function AuthPage({ onLogin }) {
  const navigate = useNavigate();

  const [mode, setMode] = useState("login"); 
  const [showPassword, setShowPassword] = useState(false);
  const [cooldown, setCooldown] = useState(0);
  const [formData, setFormData] = useState({
    email: "",
    password: "",
    first_name: "",
    last_name: ""
  });

  const [message, setMessage] = useState({ type: "", text: "" });

  useEffect(() => {
    if (cooldown <= 0) return;
    const t = setInterval(() => setCooldown((c) => c - 1), 1000);
    return () => clearInterval(t);
  }, [cooldown]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setMessage({ type: "", text: "" });

    try {
      const endpoint =
        mode === "login" ? "/auth/login" : mode === "register" ? "/auth/register" : "/auth/forgot-password";

      const res = await axios.post(`${AUTH_SERVICE_URL}${endpoint}`, formData);

      if (mode === "login") {
        onLogin(res.data.user, res.data.access_token);
        navigate("/");
      } else if (mode === "forgot") {
        setCooldown(60);
        setMessage({ type: "success", text: "Reset code sent! Redirecting..." });
        setTimeout(() => navigate("/reset-password"), 2000);
      } else {
        setMessage({ type: "success", text: "Account created! Please sign in." });
        setMode("login");
      }
    } catch (err) {
      setMessage({ type: "error", text: err.response?.data?.detail || "Request failed." });
    }
  };

  const buttonBaseClass = "py-3 rounded-lg font-bold text-white shadow-md transition-all active:scale-[0.98] bg-green-700 hover:bg-green-800";

  return (
    <div className="max-w-md mx-auto my-12 p-10 rounded-2xl border border-green-300 shadow-lg bg-white">
      <h2 className="text-4xl font-bold text-center text-green-900 mb-10 uppercase tracking-tight">
        {mode === "login" ? "Login" : mode === "register" ? "Sign Up" : "Reset"}
      </h2>

      {message.text && (
        <div className={`mb-6 p-3 rounded text-center font-medium border ${
            message.type === "error" ? "bg-red-50 text-red-700 border-red-200" : "bg-green-50 text-green-900 border-green-200"
          }`}>
          {message.text}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        {mode === "register" && (
          <div className="flex gap-2">
          </div>
        )}

        <input
          type="email" required placeholder="Email address" value={formData.email}
          className="w-full px-4 py-4 rounded-xl bg-[#ecf9ec] text-green-900 border border-green-300 focus:outline-none focus:ring-2 focus:ring-green-600"
          onChange={(e) => setFormData({ ...formData, email: e.target.value })}
        />

        {mode !== "forgot" && (
          <div className="relative">
            <input
              type={showPassword ? "text" : "password"} required placeholder="Password"
              className="w-full px-4 py-4 pr-14 rounded-xl bg-[#ecf9ec] text-green-900 border border-green-300 focus:outline-none focus:ring-2 focus:ring-green-600"
              onChange={(e) => setFormData({ ...formData, password: e.target.value })}
            />
            <button
              type="button" onClick={() => setShowPassword(!showPassword)}
              className="absolute right-4 top-1/2 -translate-y-1/2 bg-transparent border-none p-0 text-green-600 hover:text-green-800 focus:outline-none"
            >
              {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
            </button>
          </div>
        )}

        <button
          type="submit"
          disabled={mode === "forgot" && cooldown > 0}
          className={`w-full ${buttonBaseClass} ${cooldown > 0 ? "opacity-50 cursor-not-allowed" : ""}`}
        >
          {mode === "login" ? "Sign In" : mode === "register" ? "Create Account" : "Send Reset Code"}
        </button>
      </form>

      {/* MODIFIED BOTTOM SECTION: Removed "Back to Login" */}
      {mode === "login" && (
        <div className="mt-8 flex justify-center gap-4">
          <button
            onClick={() => { setMode("register"); setMessage({type:"", text:""}); }}
            className={`flex-1 ${buttonBaseClass} px-2 py-2.5 text-sm`}
          >
            Sign Up
          </button>
          <button
            onClick={() => { setMode("forgot"); setMessage({type:"", text:""}); }}
            className={`flex-1 ${buttonBaseClass} px-2 py-2.5 text-sm`}
          >
            Forgot Password?
          </button>
        </div>
      )}
    </div>
  );
}

export default AuthPage;