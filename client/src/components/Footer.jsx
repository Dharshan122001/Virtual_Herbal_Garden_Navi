// /client/src/components/Footer.jsx
import React from 'react';
function Footer() {
    return (
        <footer className="bg-gray-800 text-white p-6 mt-8 shadow-inner">
            <div className="container mx-auto text-center">
                <p>&copy; {new Date().getFullYear()} Virtual Herbal Garden. All rights reserved.</p>
                <p className="text-sm mt-2">
                    Disclaimer: Information provided is for educational purposes only and not intended as medical advice. Consult a healthcare professional before using herbal remedies.
                </p>
            </div>
        </footer>
    );
}

export default Footer;