import React, { useState } from "react";
import axios from "axios";
import { useSearchParams, useNavigate } from "react-router-dom";
import { Eye, EyeOff, ArrowLeft, KeyRound } from "lucide-react";

function ResetPassword() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);

  const [data, setData] = useState({
    email: "",
    resetId: searchParams.get("code") || "", // Still grabs from URL if link is clicked
    new_password: "",
  });

  const [msg, setMsg] = useState("");
  const [error, setError] = useState("");

  const handleReset = async (e) => {
    e.preventDefault();
    setMsg("");
    setError("");
    setLoading(true);

    try {
      await axios.post(
        `${import.meta.env.VITE_AUTH_API}/auth/reset-password`,
        data
      );
      setMsg("Password updated successfully! Redirecting to login...");
      setTimeout(() => navigate("/login"), 3000);
    } catch (err) {
      setError(err.response?.data?.detail || "Reset failed. Please check your code and email.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-md mx-auto my-12 p-8 rounded-xl border border-green-300 shadow-lg bg-white">
      <div className="flex justify-center mb-4">
        <div className="p-3 bg-green-100 rounded-full text-green-700">
          <KeyRound size={32} />
        </div>
      </div>

      <h2 className="text-3xl font-bold text-center text-green-900 mb-2">
        Update Password
      </h2>
      <p className="text-center text-gray-500 mb-8 text-sm">
        Enter your email and the code sent to you.
      </p>

      {/* Success/Error Messages */}
      {(msg || error) && (
        <div className={`mb-6 p-3 rounded text-center font-medium border ${
          error ? "bg-red-50 text-red-700 border-red-200" : "bg-green-50 text-green-900 border-green-200"
        }`}>
          {msg || error}
        </div>
      )}

      <form onSubmit={handleReset} className="space-y-5">
        {/* Email Verification */}
        <div>
          <label className="block text-xs font-bold text-green-700 uppercase ml-1 mb-1">Registered Email</label>
          <input
            type="email"
            required
            placeholder="Confirm your email"
            value={data.email}
            onChange={(e) => setData({ ...data, email: e.target.value })}
            className="w-full px-4 py-3 rounded-lg bg-[#ecf9ec] text-green-900 border border-green-300 focus:outline-none focus:ring-2 focus:ring-green-600"
          />
        </div>

        {/* Reset Code Field (Manual Paste) */}
        <div>
          <label className="block text-xs font-bold text-green-700 uppercase ml-1 mb-1">Reset Code</label>
          <input
            type="text"
            required
            placeholder="Paste code from email"
            value={data.resetId}
            onChange={(e) => setData({ ...data, resetId: e.target.value })}
            className="w-full px-4 py-3 rounded-lg bg-[#f0fff0] text-green-900 border-2 border-dashed border-green-400 focus:outline-none focus:ring-2 focus:ring-green-600 font-mono text-center tracking-widest"
          />
        </div>

        {/* New Password */}
        <div className="relative">
          <label className="block text-xs font-bold text-green-700 uppercase ml-1 mb-1">New Password</label>
          <input
            type={showPassword ? "text" : "password"}
            required
            placeholder="Min 8 characters"
            className="w-full px-4 py-3 pr-12 rounded-lg bg-[#ecf9ec] text-green-900 border border-green-300 focus:outline-none focus:ring-2 focus:ring-green-600"
            onChange={(e) => setData({ ...data, new_password: e.target.value })}
          />
          <button
            type="button"
            onClick={() => setShowPassword(!showPassword)}
            className="absolute right-4 top-[34px] bg-transparent border-none p-0 text-green-600 hover:text-green-800 focus:outline-none"
            style={{ background: 'none', border: 'none' }}
          >
            {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
          </button>
        </div>

        {/* Action Button */}
        <button
          type="submit"
          disabled={loading}
          className="w-full py-3 rounded-lg font-bold text-white bg-green-700 hover:bg-green-800 shadow-md transition-all active:scale-[0.98] disabled:bg-green-300"
        >
          {loading ? "Processing..." : "Update Password"}
        </button>
      </form>
    </div>
  );
}

export default ResetPassword;
// #everything is working fine