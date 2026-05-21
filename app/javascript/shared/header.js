// Toggle User Menu
function toggleUserMenu() {
  const dropdown = document.getElementById('userDropdown');
  dropdown.classList.toggle('show');
}

// Close dropdown when clicking outside
document.addEventListener('click', function(event) {
  const profileBtn = document.querySelector('.fb-profile-btn');
  const userDropdown = document.getElementById('userDropdown');
  
  if (profileBtn && userDropdown && !profileBtn.contains(event.target) && !userDropdown.contains(event.target)) {
    userDropdown.classList.remove('show');
  }
});
