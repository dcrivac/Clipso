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

// Paddle Configuration - PRODUCTION (live payments)
const PADDLE_VENDOR_ID = 'live_fc98babc1d8bb9e39a3482fd2bc'; // Paddle Production client-side token
const PADDLE_ENVIRONMENT = 'production'; // Use 'sandbox' for testing, 'production' for live
const LIFETIME_PRICE_ID = 'pri_01kfqf26bqncwbr7nvrg445esy'; // Lifetime (one-time $29.99) - Production
const ANNUAL_PRICE_ID = 'pri_01kfqf40kc2jn9cgx9a6naenk7'; // Annual subscription ($7.99/year) - Production

// Initialize Paddle
function initializePaddle() {
    if (window.Paddle) {
        // Only set environment for sandbox, production is default
        if (PADDLE_ENVIRONMENT === 'sandbox') {
            Paddle.Environment.set('sandbox');
        }
        Paddle.Initialize({
            token: PADDLE_VENDOR_ID,
            eventCallback: function(event) {
                if (event.name === 'checkout.completed') {
                    // Show success message
                    alert('Thank you for your purchase! Check your email for your license key.');
                    console.log('Purchase successful', event);
                }
            }
        });
    }
}

// Wait for Paddle to load
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializePaddle);
} else {
    initializePaddle();
}

// Paddle Checkout Functions
function openLifetimeCheckout() {
    if (typeof window.Paddle === 'undefined') {
        alert('Payment system loading... Please try again in a moment.');
        return;
    }

    // Open Paddle checkout
    Paddle.Checkout.open({
        items: [{ priceId: LIFETIME_PRICE_ID, quantity: 1 }]
    });
}

function openAnnualCheckout() {
    if (typeof window.Paddle === 'undefined') {
        alert('Payment system loading... Please try again in a moment.');
        return;
    }

    // Open Paddle checkout
    Paddle.Checkout.open({
        items: [{ priceId: ANNUAL_PRICE_ID, quantity: 1 }]
    });
}

// Attach checkout functions to buttons (after DOM loads)
document.addEventListener('DOMContentLoaded', function() {
    // Find all "Get Pro" buttons and attach checkout
    const proButtons = document.querySelectorAll('a[href*="Get Lifetime Pro"], a[href*="Get Pro"]');
    proButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            openLifetimeCheckout();
        });
    });

    // Annual pro buttons
    const annualButtons = document.querySelectorAll('a[href*="annual"]');
    annualButtons.forEach(button => {
        if (button.textContent.includes('Annual') || button.textContent.includes('$7.99')) {
            button.addEventListener('click', function(e) {
                e.preventDefault();
                openAnnualCheckout();
            });
        }
    });
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

// Mobile menu toggle
const createMobileMenu = () => {
    const navLinks = document.querySelector('.nav-links');
    const navContent = document.querySelector('.nav-content');

    if (!navLinks || !navContent) {
        console.warn('Navigation elements not found');
        return;
    }

    const menuButton = document.createElement('button');
    menuButton.className = 'mobile-menu-button';
    menuButton.innerHTML = '☰';
    menuButton.setAttribute('aria-label', 'Toggle mobile menu');
    menuButton.setAttribute('aria-expanded', 'false');
    menuButton.style.display = 'none';
    menuButton.style.background = 'none';
    menuButton.style.border = 'none';
    menuButton.style.fontSize = '1.5rem';
    menuButton.style.cursor = 'pointer';
    menuButton.style.color = 'var(--text-primary)';
    menuButton.style.padding = '0.5rem';

    let menuOpen = false;

    // Check if screen is mobile and update UI
    const checkMobile = () => {
        if (window.innerWidth <= 768) {
            menuButton.style.display = 'block';
            if (!menuOpen) {
                navLinks.classList.add('mobile-hidden');
            }
        } else {
            menuButton.style.display = 'none';
            navLinks.classList.remove('mobile-hidden', 'mobile-open');
            navLinks.removeAttribute('style');
            menuOpen = false;
            menuButton.setAttribute('aria-expanded', 'false');
        }
    };

    // Toggle mobile menu
    menuButton.addEventListener('click', () => {
        menuOpen = !menuOpen;
        menuButton.setAttribute('aria-expanded', menuOpen.toString());
        menuButton.innerHTML = menuOpen ? '✕' : '☰';

        if (menuOpen) {
            navLinks.classList.remove('mobile-hidden');
            navLinks.classList.add('mobile-open');
            navLinks.style.display = 'flex';
            navLinks.style.flexDirection = 'column';
            navLinks.style.position = 'absolute';
            navLinks.style.top = '100%';
            navLinks.style.left = '0';
            navLinks.style.right = '0';
            navLinks.style.background = 'white';
            navLinks.style.padding = '1rem';
            navLinks.style.boxShadow = '0 4px 6px rgba(0, 0, 0, 0.1)';
            navLinks.style.zIndex = '1000';
        } else {
            navLinks.classList.add('mobile-hidden');
            navLinks.classList.remove('mobile-open');
            navLinks.removeAttribute('style');
        }
    });

    // Close menu when clicking on a link
    navLinks.querySelectorAll('a').forEach(link => {
        link.addEventListener('click', () => {
            if (menuOpen && window.innerWidth <= 768) {
                menuOpen = false;
                menuButton.innerHTML = '☰';
                menuButton.setAttribute('aria-expanded', 'false');
                navLinks.classList.add('mobile-hidden');
                navLinks.classList.remove('mobile-open');
                navLinks.removeAttribute('style');
            }
        });
    });

    navContent.insertBefore(menuButton, navLinks);
    window.addEventListener('resize', checkMobile);
    checkMobile();
};

// Initialize mobile menu on all devices (responsive behavior handled inside)
document.addEventListener('DOMContentLoaded', () => {
    createMobileMenu();
});

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

// Download button analytics
document.querySelectorAll('a[href*="releases"]').forEach(button => {
    button.addEventListener('click', () => {
        // Track download button clicks
        if (typeof gtag !== 'undefined') {
            gtag('event', 'download', {
                'event_category': 'engagement',
                'event_label': 'download_button',
                'value': 1
            });
        }
    });
});

// GitHub button analytics
document.querySelectorAll('a[href*="github.com"]').forEach(button => {
    button.addEventListener('click', () => {
        // Track GitHub link clicks
        if (typeof gtag !== 'undefined') {
            gtag('event', 'click', {
                'event_category': 'outbound',
                'event_label': 'github_link',
                'transport_type': 'beacon'
            });
        }
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

// Waitlist form submission handling with error handling
document.addEventListener('DOMContentLoaded', () => {
    const waitlistForm = document.querySelector('.waitlist-form');

    if (!waitlistForm) {
        return; // Form not found on this page
    }

    const emailInput = waitlistForm.querySelector('input[type="email"]');
    const submitButton = waitlistForm.querySelector('button[type="submit"]');
    const originalButtonText = submitButton.textContent;

    // Create status message element
    const statusMessage = document.createElement('div');
    statusMessage.className = 'form-status-message';
    statusMessage.style.marginTop = '1rem';
    statusMessage.style.padding = '1rem';
    statusMessage.style.borderRadius = '0.5rem';
    statusMessage.style.fontSize = '0.875rem';
    statusMessage.style.fontWeight = '500';
    statusMessage.style.display = 'none';
    waitlistForm.appendChild(statusMessage);

    // Email validation
    function isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    // Show status message
    function showStatus(message, type) {
        statusMessage.textContent = message;
        statusMessage.style.display = 'block';

        if (type === 'success') {
            statusMessage.style.background = 'linear-gradient(135deg, #D1FAE5 0%, #A7F3D0 100%)';
            statusMessage.style.color = '#065F46';
            statusMessage.style.border = '2px solid #10B981';
        } else if (type === 'error') {
            statusMessage.style.background = 'linear-gradient(135deg, #FEE2E2 0%, #FECACA 100%)';
            statusMessage.style.color = '#991B1B';
            statusMessage.style.border = '2px solid #EF4444';
        } else if (type === 'loading') {
            statusMessage.style.background = 'linear-gradient(135deg, #DBEAFE 0%, #BFDBFE 100%)';
            statusMessage.style.color = '#1E40AF';
            statusMessage.style.border = '2px solid #3B82F6';
        }
    }

    // Hide status message
    function hideStatus() {
        statusMessage.style.display = 'none';
    }

    // Set button loading state
    function setButtonLoading(isLoading) {
        if (isLoading) {
            submitButton.disabled = true;
            submitButton.textContent = 'Joining...';
            submitButton.style.opacity = '0.7';
            submitButton.style.cursor = 'not-allowed';
        } else {
            submitButton.disabled = false;
            submitButton.textContent = originalButtonText;
            submitButton.style.opacity = '1';
            submitButton.style.cursor = 'pointer';
        }
    }

    // Handle form submission
    waitlistForm.addEventListener('submit', async (e) => {
        e.preventDefault();

        const email = emailInput.value.trim();

        // Validate email
        if (!email) {
            showStatus('Please enter your email address', 'error');
            emailInput.focus();
            return;
        }

        if (!isValidEmail(email)) {
            showStatus('Please enter a valid email address', 'error');
            emailInput.focus();
            return;
        }

        // Show loading state
        hideStatus();
        setButtonLoading(true);
        showStatus('Adding you to the waitlist...', 'loading');

        try {
            // Submit to Formspree
            const formData = new FormData(waitlistForm);
            const response = await fetch(waitlistForm.action, {
                method: 'POST',
                body: formData,
                headers: {
                    'Accept': 'application/json'
                }
            });

            if (response.ok) {
                // Success
                showStatus('🎉 Success! Check your email to confirm your subscription.', 'success');
                waitlistForm.reset();

                // Track conversion (if analytics enabled)
                if (typeof gtag !== 'undefined') {
                    gtag('event', 'waitlist_signup', {
                        'event_category': 'engagement',
                        'event_label': 'waitlist_form'
                    });
                }

                // Hide success message after 10 seconds
                setTimeout(() => {
                    hideStatus();
                }, 10000);
            } else {
                // Formspree returned an error
                const data = await response.json();

                if (data.errors) {
                    const errorMessages = data.errors.map(err => err.message).join(', ');
                    showStatus(`Error: ${errorMessages}`, 'error');
                } else {
                    showStatus('Something went wrong. Please try again.', 'error');
                }
            }
        } catch (error) {
            // Network error or other issue
            console.error('Form submission error:', error);
            showStatus('Network error. Please check your connection and try again.', 'error');
        } finally {
            setButtonLoading(false);
        }
    });

    // Real-time email validation feedback
    let validationTimeout;
    emailInput.addEventListener('input', () => {
        clearTimeout(validationTimeout);
        hideStatus();

        validationTimeout = setTimeout(() => {
            const email = emailInput.value.trim();
            if (email && !isValidEmail(email)) {
                emailInput.style.borderColor = '#EF4444';
            } else {
                emailInput.style.borderColor = '';
            }
        }, 500);
    });

    // Clear validation on focus
    emailInput.addEventListener('focus', () => {
        emailInput.style.borderColor = '';
        hideStatus();
    });
});

// Console Easter egg
console.log('%c👋 Hello Developer!', 'font-size: 20px; font-weight: bold; color: #6366F1;');
console.log('%cInterested in how Clipso works?', 'font-size: 14px; color: #6B7280;');
console.log('%cCheck out the source code: https://github.com/dcrivac/Clipso', 'font-size: 14px; color: #6366F1;');
console.log('%c✨ Built with Swift, SwiftUI, and Apple\'s on-device ML frameworks', 'font-size: 12px; color: #10B981;');
