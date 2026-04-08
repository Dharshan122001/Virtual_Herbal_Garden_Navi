import React, { useState, useEffect, useCallback } from "react";
import { Routes, Route } from "react-router-dom";
import axios from "axios";

import Navbar from "./components/Navbar";
import PlantList from "./components/PlantList";
import PlantDetail from "./components/PlantDetail";
import AIChatAssistant from "./components/AIChatAssistant";
import IdentifyPlant from "./components/IdentifyPlant";
import Home from "./components/Home";
import AuthPage from "./components/AuthPage";
import ResetPassword from "./components/ResetPassword";

import { PLANT_SERVICE_URL } from "./apiConfig"; // ✅ Correct for App.jsx



function App() {
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem("user");
    return saved ? JSON.parse(saved) : null;
  });

  const [userBookmarks, setUserBookmarks] = useState(new Set());
  const [showBookmarkedOnly, setShowBookmarkedOnly] = useState(false);

  const fetchUserBookmarks = useCallback(async (currentUser) => {
    const token = localStorage.getItem("token");
    if (!currentUser || !token) {
      setUserBookmarks(new Set());
      return;
    }

    try {
      const res = await axios.get(
        `${PLANT_SERVICE_URL}/bookmarks/user/${currentUser.email}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      setUserBookmarks(new Set(res.data.map(b => b.plant_id)));
    } catch {
      setUserBookmarks(new Set());
    }
  }, []);

  useEffect(() => {
    if (user) fetchUserBookmarks(user);
    else setUserBookmarks(new Set());
  }, [user, fetchUserBookmarks]);

  const handleLogin = (userData, token) => {
    localStorage.setItem("token", token);
    localStorage.setItem("user", JSON.stringify(userData));
    setUser(userData);
  };

  const handleLogout = () => {
    localStorage.clear();
    setUser(null);
    setUserBookmarks(new Set());
    setShowBookmarkedOnly(false);
  };

  const handleBookmarkToggled = useCallback((plantId, wasBookmarked) => {
    setUserBookmarks(prev => {
      const updated = new Set(prev);
      wasBookmarked ? updated.delete(plantId) : updated.add(plantId);
      return updated;
    });
  }, []);

return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <Navbar user={user} onLogout={handleLogout} showBookmarkedOnly={showBookmarkedOnly} setShowBookmarkedOnly={setShowBookmarkedOnly} />
      <main className="flex-grow container mx-auto px-4 py-8">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/plants" element={<PlantList userBookmarks={userBookmarks} onBookmarkToggled={handleBookmarkToggled} showBookmarkedOnly={showBookmarkedOnly} />} />
          <Route path="/plants/:plantId" element={<PlantDetail userBookmarks={userBookmarks} onBookmarkToggled={handleBookmarkToggled} />} />
          <Route path="/ai-assistant" element={<AIChatAssistant />} />
          <Route path="/identify" element={<IdentifyPlant />} />
          <Route path="/login" element={<AuthPage onLogin={handleLogin} />} />
          <Route path="/reset-password" element={<ResetPassword />} />
        </Routes>
      </main>
      <footer className="bg-gray-800 text-white text-center p-4">© 2025 Virtual Herbal Garden</footer>
    </div>
  );
}
export default App;