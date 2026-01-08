// Navbar scroll effect
let lastScroll = 0;
const nav = document.querySelector('.nav');

window.addEventListener('scroll', () => {
    const currentScroll = window.pageYOffset;

    if (currentScroll > 100) {
        nav.style.boxShadow = '0 2px 10px rgba(0, 0, 0, 0.1)';
    } else {
        nav.style.boxShadow = 'none';
    }

    lastScroll = currentScroll;
});

// Animated typing effect for demo search
const demoSearch = document.querySelector('.demo-search');
const searchQueries = [
    'machine learning tutorials',
    'API documentation',
    'coffee recipes',
    'git commands',
    'design inspiration'
];

let currentQueryIndex = 0;
let currentCharIndex = 0;
let isDeleting = false;
let typingSpeed = 100;

function typeSearchQuery() {
    const currentQuery = searchQueries[currentQueryIndex];

    if (isDeleting) {
        demoSearch.placeholder = 'Search by meaning or keywords... ' + currentQuery.substring(0, currentCharIndex - 1);
        currentCharIndex--;
        typingSpeed = 50;
    } else {
        demoSearch.placeholder = 'Search by meaning or keywords... ' + currentQuery.substring(0, currentCharIndex + 1);
        currentCharIndex++;
        typingSpeed = 100;
    }

    if (!isDeleting && currentCharIndex === currentQuery.length) {
        typingSpeed = 2000; // Pause at end
        isDeleting = true;
    } else if (isDeleting && currentCharIndex === 0) {
        isDeleting = false;
        currentQueryIndex = (currentQueryIndex + 1) % searchQueries.length;
        typingSpeed = 500; // Pause before next query
    }

    setTimeout(typeSearchQuery, typingSpeed);
}

// Start typing animation
setTimeout(() => {
    typeSearchQuery();
}, 1000);

// Intersection Observer for fade-in animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Add fade-in animation to sections
document.querySelectorAll('.feature-showcase, .feature-card, .guarantee, .problem-card').forEach(el => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(30px)';
    el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
    observer.observe(el);
});

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            const navHeight = nav.offsetHeight;
            const targetPosition = target.offsetTop - navHeight;
            window.scrollTo({
                top: targetPosition,
                behavior: 'smooth'
            });
        }
    });
});

// Mobile menu toggle (for future implementation)
const createMobileMenu = () => {
    const navLinks = document.querySelector('.nav-links');
    const menuButton = document.createElement('button');
    menuButton.className = 'mobile-menu-button';
    menuButton.innerHTML = '☰';
    menuButton.style.display = 'none';
    menuButton.style.background = 'none';
    menuButton.style.border = 'none';
    menuButton.style.fontSize = '1.5rem';
    menuButton.style.cursor = 'pointer';
    menuButton.style.color = 'var(--text-primary)';

    // Check if screen is mobile
    const checkMobile = () => {
        if (window.innerWidth <= 768) {
            menuButton.style.display = 'block';
        } else {
            menuButton.style.display = 'none';
            navLinks.style.display = 'flex';
        }
    };

    menuButton.addEventListener('click', () => {
        if (navLinks.style.display === 'none' || navLinks.style.display === '') {
            navLinks.style.display = 'flex';
            navLinks.style.flexDirection = 'column';
            navLinks.style.position = 'absolute';
            navLinks.style.top = '100%';
            navLinks.style.left = '0';
            navLinks.style.right = '0';
            navLinks.style.background = 'white';
            navLinks.style.padding = '1rem';
            navLinks.style.boxShadow = '0 4px 6px rgba(0, 0, 0, 0.1)';
        } else {
            navLinks.style.display = 'none';
        }
    });

    document.querySelector('.nav-content').insertBefore(menuButton, navLinks);
    window.addEventListener('resize', checkMobile);
    checkMobile();
};

// Initialize mobile menu
if (window.innerWidth <= 768) {
    createMobileMenu();
}

// Add particle effect to hero section
const createParticles = () => {
    const hero = document.querySelector('.hero');
    const particlesContainer = document.createElement('div');
    particlesContainer.style.position = 'absolute';
    particlesContainer.style.top = '0';
    particlesContainer.style.left = '0';
    particlesContainer.style.width = '100%';
    particlesContainer.style.height = '100%';
    particlesContainer.style.overflow = 'hidden';
    particlesContainer.style.pointerEvents = 'none';
    particlesContainer.style.zIndex = '0';

    for (let i = 0; i < 20; i++) {
        const particle = document.createElement('div');
        particle.style.position = 'absolute';
        particle.style.width = Math.random() * 4 + 2 + 'px';
        particle.style.height = particle.style.width;
        particle.style.borderRadius = '50%';
        particle.style.background = `rgba(99, 102, 241, ${Math.random() * 0.3 + 0.1})`;
        particle.style.left = Math.random() * 100 + '%';
        particle.style.top = Math.random() * 100 + '%';
        particle.style.animation = `float ${Math.random() * 10 + 10}s ease-in-out infinite`;
        particle.style.animationDelay = Math.random() * 5 + 's';
        particlesContainer.appendChild(particle);
    }

    hero.style.position = 'relative';
    hero.insertBefore(particlesContainer, hero.firstChild);

    // Make sure hero content is above particles
    const heroContent = hero.querySelector('.hero-content');
    const heroVisual = hero.querySelector('.hero-visual');
    if (heroContent) heroContent.style.position = 'relative';
    if (heroVisual) heroVisual.style.position = 'relative';
};

// Add particles on desktop only
if (window.innerWidth > 768) {
    createParticles();
}

// Download button analytics (placeholder)
document.querySelectorAll('a[href*="releases"]').forEach(button => {
    button.addEventListener('click', () => {
        console.log('Download button clicked');
        // Add analytics tracking here
    });
});

// GitHub button analytics (placeholder)
document.querySelectorAll('a[href*="github.com"]').forEach(button => {
    button.addEventListener('click', () => {
        console.log('GitHub button clicked');
        // Add analytics tracking here
    });
});

// Feature card hover effect enhancement
document.querySelectorAll('.feature-card').forEach(card => {
    card.addEventListener('mouseenter', () => {
        card.style.transition = 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)';
    });
});

// Clipboard item animation in demo window
const clipboardItems = document.querySelectorAll('.clipboard-item');
clipboardItems.forEach((item, index) => {
    setTimeout(() => {
        item.style.animation = 'slideIn 0.5s ease-out forwards';
        item.style.opacity = '0';
        setTimeout(() => {
            item.style.opacity = '1';
        }, index * 100);
    }, 2000 + index * 200);
});

// Add keyboard shortcut hint
document.addEventListener('keydown', (e) => {
    // Cmd+Shift+V or Ctrl+Shift+V
    if ((e.metaKey || e.ctrlKey) && e.shiftKey && e.key === 'V') {
        e.preventDefault();
        const featuresSection = document.querySelector('#features');
        if (featuresSection) {
            featuresSection.scrollIntoView({ behavior: 'smooth' });

            // Show a temporary hint
            const hint = document.createElement('div');
            hint.textContent = '⌘⇧V - Try this shortcut in the app!';
            hint.style.position = 'fixed';
            hint.style.bottom = '2rem';
            hint.style.right = '2rem';
            hint.style.background = 'linear-gradient(135deg, #6366F1, #8B5CF6)';
            hint.style.color = 'white';
            hint.style.padding = '1rem 1.5rem';
            hint.style.borderRadius = '0.5rem';
            hint.style.boxShadow = '0 10px 25px rgba(0, 0, 0, 0.2)';
            hint.style.zIndex = '10000';
            hint.style.animation = 'slideIn 0.3s ease-out';

            document.body.appendChild(hint);

            setTimeout(() => {
                hint.style.animation = 'slideOut 0.3s ease-in';
                setTimeout(() => hint.remove(), 300);
            }, 3000);
        }
    }
});

// Add CSS for hint animations
const style = document.createElement('style');
style.textContent = `
    @keyframes slideOut {
        from {
            opacity: 1;
            transform: translateY(0);
        }
        to {
            opacity: 0;
            transform: translateY(20px);
        }
    }
`;
document.head.appendChild(style);

// Performance optimization: Lazy load images (future feature)
if ('IntersectionObserver' in window) {
    const imageObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                if (img.dataset.src) {
                    img.src = img.dataset.src;
                    img.removeAttribute('data-src');
                    imageObserver.unobserve(img);
                }
            }
        });
    });

    document.querySelectorAll('img[data-src]').forEach(img => {
        imageObserver.observe(img);
    });
}

// Console Easter egg
console.log('%c👋 Hello Developer!', 'font-size: 20px; font-weight: bold; color: #6366F1;');
console.log('%cInterested in how Clipso works?', 'font-size: 14px; color: #6B7280;');
console.log('%cCheck out the source code: https://github.com/dcrivac/Clipso', 'font-size: 14px; color: #6366F1;');
console.log('%c✨ Built with Swift, SwiftUI, and Apple\'s on-device ML frameworks', 'font-size: 12px; color: #10B981;');
