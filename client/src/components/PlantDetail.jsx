import React, { useState, useEffect, useCallback } from "react";
import { useParams } from "react-router-dom";
import axios from "axios";
import { FaBookmark, FaRegBookmark } from "react-icons/fa";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { PLANT_SERVICE_URL, AI_SERVICE_URL } from "../apiConfig";

function PlantDetail({ userBookmarks = new Set(), onBookmarkToggled }) {
  const { plantId } = useParams();
  const plantIdNum = Number(plantId);

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [plant, setPlant] = useState(null);

  const [aiResponse, setAiResponse] = useState("");
  const [aiLoading, setAiLoading] = useState(false);
  const [aiError, setAiError] = useState(null);
  const [activeQuery, setActiveQuery] = useState(null);

  const token = localStorage.getItem("token");
  const dbUser = JSON.parse(localStorage.getItem("user") || "null");
  const isBookmarked = userBookmarks.has(plantIdNum);

  const fetchPlantDetail = useCallback(async () => {
    try {
      setLoading(true);
      const res = await axios.get(`${PLANT_SERVICE_URL}/plants/${plantIdNum}`);
      setPlant(res.data);
      setError(null);
    } catch {
      setError("Failed to load plant details.");
    } finally {
      setLoading(false);
    }
  }, [plantIdNum, PLANT_API]);

  useEffect(() => { fetchPlantDetail(); }, [fetchPlantDetail]);

  const handleBookmarkToggle = async () => {
    if (!token || !dbUser) {
      alert("Please log in to bookmark plants.");
      return;
    }
    try {
      const config = { headers: { Authorization: `Bearer ${token}` } };
      if (isBookmarked) {
        await axios.delete(`${PLANT_SERVICE_URL}/bookmarks/${dbUser.email}/${plantIdNum}`, config);
      } else {
        await axios.post(`${PLANT_SERVICE_URL}/bookmarks/`, { email: dbUser.email, plant_id: plantIdNum }, config);
      }
      onBookmarkToggled?.(plantIdNum, isBookmarked);
    } catch (err) {
      alert(err.response?.data?.detail || "Failed to update bookmark.");
    }
  };

  const askAIAboutPlant = async (queryType) => {
    if (!plant?.common_name) return;
    setAiLoading(true);
    setAiError(null);
    setActiveQuery(queryType);
    setAiResponse(""); 

    const prompts = {
      combinations: `For the plant "${plant.common_name}", explain its common uses when combined with other herbs.`,
      allergies: `For the plant "${plant.common_name}", list known allergens.`,
      allergenic_mixtures: `For the plant "${plant.common_name}", describe dangerous mixtures.`
    };

    try {
      const res = await axios.post(`${AI_SERVICE_URL}/ai/chat`, { message: prompts[queryType] });
      setAiResponse(res.data.response);
    } catch (err) {
      setAiError("Failed to get AI response.");
    } finally {
      setAiLoading(false);
    }
  };

  if (loading) return <div className="text-center py-10 font-medium text-green-800">Loading plant details...</div>;
  if (error || !plant) return <div className="text-center text-red-600 py-10">{error || "Plant not found."}</div>;

  return (
    <div className="bg-white rounded-lg shadow-xl p-8 my-8 border border-gray-200 max-w-4xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-6 pb-4 border-b">
        <h1 className="text-4xl font-extrabold text-green-800">
          {plant.common_name || plant.scientific_name}
        </h1>
        {token && (
          <button onClick={handleBookmarkToggle}>
            {isBookmarked ? (
              <FaBookmark className="text-green-600 text-3xl transition-transform hover:scale-110" />
            ) : (
              <FaRegBookmark className="text-3xl text-gray-400 transition-transform hover:scale-110" />
            )}
          </button>
        )}
      </div>

      {/* Image */}
      {plant.image_url && (
        <div className="mb-6 flex justify-center">
          <img src={plant.image_url} alt={plant.common_name} className="max-w-lg rounded-2xl shadow-lg border-4 border-white" />
        </div>
      )}

      {/* Standard Info */}
      <div className="space-y-4 text-gray-700 text-lg mb-8">
        <p><strong className="text-green-700">Description:</strong> {plant.description}</p>
        {plant.scientific_name && <p className="italic"><strong className="text-green-700">Scientific Name:</strong> {plant.scientific_name}</p>}
        {plant.uses && <p><strong className="text-green-700">Uses:</strong> {plant.uses.join(", ")}</p>}
      </div>

      {/* ================= AI SECTION ================= */}
      <div className="mt-8 pt-6 border-t border-gray-100">
        <h2 className="text-2xl font-bold mb-4 text-green-900">AI Expert Insights</h2>
        
        {/* Interaction Buttons */}
        <div className="flex gap-3 mb-6 flex-wrap">
          {["combinations", "allergies", "allergenic_mixtures"].map((type) => (
            <button
              key={type}
              onClick={() => askAIAboutPlant(type)}
              className={`px-5 py-2 rounded-full border text-sm font-bold transition-all shadow-sm ${
                activeQuery === type 
                  ? "bg-green-700 text-white border-green-700 ring-2 ring-green-200" 
                  : "bg-white text-green-700 border-green-200 hover:bg-green-50"
              }`}
            >
              {type.replace("_", " ").toUpperCase()}
            </button>
          ))}
        </div>

        {/* Loading State */}
        {aiLoading && (
          <div className="flex items-center gap-2 text-green-600 font-bold animate-pulse mb-4">
            <span>🌿</span> Analyzing herbal data...
          </div>
        )}

        {/* AI Output Container - FORCED DARK GREEN TEXT */}
        {aiResponse && (
          <div className="bg-emerald-50 p-8 rounded-2xl border border-emerald-100 shadow-inner">
            <div className="prose max-w-none 
                            text-gray-900
                            prose-headings:text-green-950
                            prose-p:text-gray-950
                            prose-li:text-green-950
                            prose-strong:text-green-900">
              <ReactMarkdown remarkPlugins={[remarkGfm]}>{aiResponse}</ReactMarkdown>
            </div>
          </div>
        )}

        {aiError && <p className="text-red-600 italic bg-red-50 p-4 rounded-lg border border-red-100">{aiError}</p>}
      </div>
    </div>
  );
}

export default PlantDetail;