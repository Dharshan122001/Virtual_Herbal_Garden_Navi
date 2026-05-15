import React from "react";
import { Link, useLocation } from "react-router-dom";

function Navbar({ user, onLogout, showBookmarkedOnly, setShowBookmarkedOnly }) {
  const location = useLocation();
  const isPlantsPage = location.pathname === "/plants";

  const linkClass =
    "text-[#c2ecc2] hover:text-[#ecf9ec] transition-colors duration-200";

  return (
    <nav className="bg-green-800 shadow-lg px-6 py-4">
      <div className="container mx-auto flex justify-between items-center">

        {/* Logo */}
        <Link
          to="/"
          className="text-2xl font-extrabold tracking-wide text-[#c2ecc2] hover:text-[#ecf9ec] transition-colors duration-200"
        >
          Virtual Herbal Garden
        </Link>

        {/* Navigation Links */}
        <div className="hidden md:flex space-x-6 font-medium">
          <Link to="/" className={linkClass}>Home</Link>
          <Link to="/plants" className={linkClass}>Browse Plants</Link>
          <Link to="/ai-assistant" className={linkClass}>AI Assistant</Link>
          <Link to="/identify" className={linkClass}>Identify Plant</Link>
        </div>

        {/* Right section */}
        <div className="flex items-center space-x-4">

          {/* Favorites toggle */}
          {user && isPlantsPage && (
            <label className="flex items-center bg-green-700 px-3 py-1 rounded-full text-sm text-[#c2ecc2]">
              <span className="mr-2">Favorites</span>
              <input
                type="checkbox"
                checked={showBookmarkedOnly}
                onChange={(e) => setShowBookmarkedOnly(e.target.checked)}
                className="accent-green-300"
              />
            </label>
          )}

          {/* Login */}
          {!user && (
            <Link
              to="/login"
              className="bg-[#c2ecc2] text-green-900 px-4 py-2 rounded-full font-semibold hover:bg-[#ecf9ec] transition"
            >
              Login / Sign Up
            </Link>
          )}

          {/* Logout */}
          {user && (
            <button
              onClick={onLogout}
              className="bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded-full font-semibold transition"
            >
              Logout
            </button>
          )}
        </div>
      </div>
    </nav>
  );
}

export default Navbar;
