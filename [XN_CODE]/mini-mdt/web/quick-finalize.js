
// ========== QUICK FINALIZE MODAL FUNCTIONS ==========
// Note: openQuickFinalizeModal is defined in script.js

// Close Quick Finalize Modal
function closeQuickFinalize() {
    const modal = document.getElementById('quick-finalize-modal');
    if (modal) {
        modal.style.display = 'none';
        modal.classList.add('hidden');
    }
    
    // Tắt NUI focus
    fetch(`https://${GetParentResourceName()}/closeQuick`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    });
}

// Alias cho ESC handler
function closeQuickFinalizeModal() {
    closeQuickFinalize();
}

// Export to window
window.closeQuickFinalize = closeQuickFinalize;
window.closeQuickFinalizeModal = closeQuickFinalizeModal;