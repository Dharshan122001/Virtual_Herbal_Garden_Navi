import React, { useState, useEffect, useMemo, useCallback } from "react";
import axios from "axios";
import PlantCard from "./PlantCard";
import { FaSearch } from "react-icons/fa";
import { PLANT_SERVICE_URL } from "../apiConfig";

function PlantList({ userBookmarks, onBookmarkToggled, showBookmarkedOnly }) {
  const [plants, setPlants] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [submittedSearchTerm, setSubmittedSearchTerm] = useState("");

  const fetchPlants = useCallback(async () => {
    setLoading(true);
    try {
      const params = submittedSearchTerm
        ? { search_query: submittedSearchTerm }
        : {};
      const res = await axios.get(`${PLANT_SERVICE_URL}/plants`, { params });
      setPlants(res.data);
    } finally {
      setLoading(false);
    }
  }, [submittedSearchTerm, PLANT_SERVICE_URL]);

  useEffect(() => {
    fetchPlants();
  }, [fetchPlants]);

  const filteredPlants = useMemo(() => {
    if (showBookmarkedOnly) {
      return plants.filter((p) => userBookmarks.has(p.plant_id));
    }
    return plants;
  }, [plants, showBookmarkedOnly, userBookmarks]);

  if (loading) {
    return (
      <div className="text-center py-10 text-green-800 font-semibold">
        Loading plants...
      </div>
    );
  }

  return (
    <div>
      {/* SEARCH */}
      <form
        onSubmit={(e) => {
          e.preventDefault();
          setSubmittedSearchTerm(searchQuery);
        }}
        className="flex max-w-xl mx-auto mb-8"
      >
        <input
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="Search plants..."
          className="
            flex-grow px-5 py-3 rounded-l-full
            bg-[#ecf9ec]
            text-green-900
            placeholder-green-700
            border border-green-400
            focus:outline-none
            focus:ring-2 focus:ring-green-600
          "
        />

        <button
          type="submit"
          className="bg-green-700 hover:bg-green-800 text-white px-5 rounded-r-full"
        >
          <FaSearch />
        </button>
      </form>

      {/* PLANTS */}
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-6">
        {filteredPlants.map((plant) => (
          <PlantCard
            key={plant.plant_id}
            plant={plant}
            userBookmarks={userBookmarks}
            onBookmarkToggled={onBookmarkToggled}
          />
        ))}
      </div>
    </div>
  );
}

export default PlantList;
