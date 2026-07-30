// Inject logo into the Documenter sidebar
document.addEventListener('DOMContentLoaded', function() {
    var sidebar = document.querySelector('#documenter .docs-sidebar');
    if (sidebar) {
        var logoSrc = sidebar.querySelector('img') ? null : null;
        var logoDiv = document.createElement('div');
        logoDiv.className = 'docs-logo';
        var img = document.createElement('img');
        img.src = document.querySelector('link[rel="canonical"]')
            ? document.querySelector('link[rel="canonical"]').href.replace(/\/$/, '') + '/assets/logo.png'
            : 'assets/logo.png';
        img.alt = 'Glenn PlutoLab';
        logoDiv.appendChild(img);
        sidebar.insertBefore(logoDiv, sidebar.firstChild);
    }
});
