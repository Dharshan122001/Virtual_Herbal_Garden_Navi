import React, { useEffect, useState } from "react";

function AuthComponent() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  useEffect(() => {
    const token = localStorage.getItem("token");
    setIsLoggedIn(!!token);
  }, []);

  const handleLogout = () => {
    localStorage.clear();
    window.location.href = "/";
  };

  if (!isLoggedIn) return null;

  return (
    <button
      onClick={handleLogout}
      className="bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded-full font-semibold transition"
    >
      Logout
    </button>
  );
}

export default AuthComponent;
