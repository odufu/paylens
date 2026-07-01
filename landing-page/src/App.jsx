import React, { useState } from 'react';

const WHATSAPP_PHONE = "2349058145265"; // Your WhatsApp business/conversion phone number
const WHATSAPP_MESSAGE = "Hello! I am interested in enrolling in the Pay Lenses Clean Architecture Masterclass. Please share the details.";

function App() {
  const [activePhase, setActivePhase] = useState(0);
  const [currentSlide, setCurrentSlide] = useState(0);

  const togglePhase = (index) => {
    setActivePhase(activePhase === index ? null : index);
  };

  const slides = [
    {
      video: 'https://assets.mixkit.co/videos/preview/mixkit-hands-of-a-developer-typing-on-a-keyboard-40019-large.mp4',
      image: './assets/images/video_thumbnail.png',
      title: 'Pay Lenses Core App Walkthrough',
      description: 'Watch a 5-minute video demonstrating how Google Sign-In, Monnify, and VTPass work inside the mobile app.'
    },
    {
      video: 'https://assets.mixkit.co/videos/preview/mixkit-developer-working-on-code-on-a-computer-40030-large.mp4',
      image: './assets/images/clean_arch_diagram.png',
      title: 'Clean Architecture Code Walkthrough',
      description: 'Sneak peek into our test suite and GetIt container setup.'
    }
  ];

  const handleNextSlide = () => {
    setCurrentSlide((prev) => (prev + 1) % slides.length);
  };

  const handlePrevSlide = () => {
    setCurrentSlide((prev) => (prev - 1 + slides.length) % slides.length);
  };

  const handlePlayVideo = () => {
    alert('🎥 Core app demo session starts loading soon! You will get the full HD video recording inside the training curriculum dashboard.');
  };

  const getWhatsAppLink = () => {
    return `https://wa.me/${WHATSAPP_PHONE}?text=${encodeURIComponent(WHATSAPP_MESSAGE)}`;
  };

  return (
    <>
      {/* NAVIGATION HEADER */}
      <header>
        <div className="nav-container">
          <a href="#" className="nav-logo">
            PAY LENSES<span className="logo-dot"></span>
          </a>
          <nav className="nav-links">
            <a href="#features">Features</a>
            <a href="#architecture">Architecture</a>
            <a href="#curriculum">Curriculum</a>
            <a href="#demo">Demo APK</a>
            <a
              href={getWhatsAppLink()}
              target="_blank"
              rel="noopener noreferrer"
              className="btn btn-primary btn-cta"
            >
              Enroll Now
            </a>
          </nav>
        </div>
      </header>

      {/* HERO SECTION */}
      <section className="hero" style={{ position: 'relative', overflow: 'hidden', width: '100%', maxWidth: '100%', margin: '0', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '180px 24px 120px', minHeight: '80vh' }}>
        {/* Background Video */}
        <div style={{ position: 'absolute', top: 0, left: 0, width: '100%', height: '100%', zIndex: -2, overflow: 'hidden' }}>
          <video
            src="https://assets.mixkit.co/videos/preview/mixkit-hands-of-a-developer-typing-on-a-keyboard-40019-large.mp4"
            poster="./assets/images/14.png"
            autoPlay
            loop
            muted
            playsInline
            style={{ width: '100%', height: '100%', objectFit: 'cover', opacity: 0.12 }}
          />
        </div>
        {/* Radial dark overlay to make text highly readable */}
        <div style={{ position: 'absolute', top: 0, left: 0, width: '100%', height: '100%', zIndex: -1, background: 'radial-gradient(circle at center, rgba(10, 14, 23, 0.4) 0%, #0a0e17 90%)' }}></div>

        <div className="hero-content" style={{ maxWidth: '800px', textAlign: 'center', margin: '0 auto', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <span className="hero-tag">🚀 2026 PREMIUM MASTERCLASS</span>
          <h1 className="hero-title" style={{ fontSize: '64px', maxWidth: '720px', margin: '0 auto 24px', lineHeight: '1.1' }}>
            Build Fintech Apps Like a <span className="gradient-text">Senior Engineer</span>
          </h1>
          <p className="hero-desc" style={{ maxWidth: '600px', fontSize: '18px', margin: '0 auto 40px', color: 'var(--text-grey)' }}>
            A comprehensive course teaching you how to architect, design, develop, and host a highly secure mobile wealth management app using Flutter, Supabase, Monnify, and VTPass under strict Clean Architecture guidelines.
          </p>
          <div className="hero-actions" style={{ justifyContent: 'center' }}>
            <a
              href={getWhatsAppLink()}
              target="_blank"
              rel="noopener noreferrer"
              className="btn btn-primary"
            >
              Enroll in Course
            </a>
            <a href="#demo" className="btn btn-outline">Download Demo APK</a>
          </div>
          <div className="hero-stats" style={{ justifyContent: 'center', gap: '48px', marginTop: '32px' }}>
            <div>
              <div className="stat-num"><span className="stat-num-value">5 Phase</span></div>
              <div className="stat-label">Detailed Curriculum</div>
            </div>
            <div>
              <div className="stat-num"><span className="stat-num-value">10+ Hrs</span></div>
              <div className="stat-label">HD Video Sessions</div>
            </div>
            <div>
              <div className="stat-num"><span className="stat-num-value">100%</span></div>
              <div className="stat-label">Clean Code Compliant</div>
            </div>
          </div>
        </div>
      </section>

      {/* FEATURES PILLARS SECTION */}
      <section id="features">
        <div className="section-container">
          <div className="section-header">
            <span className="section-subtitle">THE CORE PILLARS</span>
            <h2 className="section-title">What You Will Master</h2>
          </div>
          <div className="pillars-grid">
            <div className="pillar-card">
              <div className="pillar-icon">🧠</div>
              <h3>Gemini AI Coding</h3>
              <p>Learn to pair program with Gemini/DeepMind AI agents to speed up restructuring, asset management, and refactoring by 10x.</p>
            </div>
            <div className="pillar-card">
              <div className="pillar-icon">🛡️</div>
              <h3>Clean Architecture</h3>
              <p>Decouple your codebase into pure Domain, Data, and Presentation layers. Write code that is testable, scale-ready, and robust.</p>
            </div>
            <div className="pillar-card">
              <div className="pillar-icon">⚡</div>
              <h3>Supabase Backend</h3>
              <p>Implement native social OAuth logins, profile database synchronization triggers, secure bucket storage, and real-time listeners.</p>
            </div>
            <div className="pillar-card">
              <div className="pillar-icon">💳</div>
              <h3>Monnify & VTPass</h3>
              <p>Integrate production payment gateways. Settle bank transfers via Monnify and automate electricity/cable utility bills with VTPass.</p>
            </div>
          </div>
        </div>
      </section>

      {/* ARCHITECTURE DETAIL SECTION */}
      <section className="arch" id="architecture">
        <div className="section-container arch-layout">
          <div className="arch-diagram">
            <img src="./assets/images/clean_arch_diagram.png" alt="Clean Architecture concentric layers diagram" />
          </div>
          <div className="arch-content">
            <span className="section-subtitle">COMPLIANT ENGINEERING</span>
            <h2 className="section-title" style={{ marginBottom: '32px' }}>Production-Grade Architecture</h2>

            <div className="arch-feature">
              <h3>Strict Dependency Rules</h3>
              <p>Make your domain layer completely independent of external packages, services, and databases. We enforce constructor injection and service locators using GetIt.</p>
            </div>

            <div className="arch-feature">
              <h3>Sealed UI State Machines</h3>
              <p>Implement bulletproof user interfaces that reactively render Loading, Success, and Failure states. No more silent app crashes.</p>
            </div>

            <div className="arch-feature">
              <h3>Mock-Based Test Coverage</h3>
              <p>Write bulletproof unit tests for your data repositories, use cases, and state controllers using mocktail, ensuring 100% logic verification.</p>
            </div>
          </div>
        </div>
      </section>

      {/* GALLERY SECTION */}
      <section id="gallery" style={{ borderTop: '1px solid var(--border-color)', borderBottom: '1px solid var(--border-color)' }}>
        <div className="section-container">
          <div className="section-header">
            <span className="section-subtitle">SCREENSHOTS</span>
            <h2 className="section-title">App Interface Showcase</h2>
          </div>
          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))',
            gap: '24px',
            marginTop: '40px'
          }}>
            {[
              {
                img: './assets/images/1.png',
                title: 'Wallet & Payments',
                desc: 'Manage virtual accounts, fund balances, and transfer funds instantly.'
              },
              {
                img: './assets/images/13.png',
                title: 'Utility Bills Settlement',
                desc: 'Automate electricity tokens and cable TV subscriptions through VTPass.'
              },
              {
                img: './assets/images/3.png',
                title: 'AI Financial Assistant',
                desc: 'Get smart savings advice, analyze spending, and chat with your budget agent.'
              },
              {
                img: './assets/images/9.png',
                title: 'Sleek Modern Design',
                desc: 'Enjoy a gorgeous forest green dark theme designed for premium branding.'
              }
            ].map((item, idx) => (
              <div
                key={idx}
                style={{
                  background: 'var(--bg-card)',
                  borderRadius: '16px',
                  border: '1px solid var(--border-color)',
                  overflow: 'hidden',
                  transition: 'all 0.3s ease',
                  cursor: 'pointer',
                }}
                className="gallery-card"
              >
                <div style={{ overflow: 'hidden', height: '380px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#080d16' }}>
                  <img
                    src={item.img}
                    alt={item.title}
                    style={{
                      width: '100%',
                      height: '100%',
                      objectFit: 'cover',
                      transition: 'transform 0.5s ease'
                    }}
                    className="gallery-img"
                  />
                </div>
                <div style={{ padding: '20px' }}>
                  <h4 style={{ fontSize: '18px', fontWeight: 'bold', marginBottom: '8px', color: '#fff' }}>{item.title}</h4>
                  <p style={{ fontSize: '13px', color: 'var(--text-grey)', lineHeight: '1.5' }}>{item.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CURRICULUM SECTION */}
      <section id="curriculum">
        <div className="section-container">
          <div className="section-header">
            <span className="section-subtitle">THE LEARNING FUNNEL</span>
            <h2 className="section-title">Masterclass Syllabus</h2>
          </div>

          <div className="curriculum-accordion">
            {/* ITEM 1 */}
            <div className={`curr-item ${activePhase === 0 ? 'active' : ''}`}>
              <div className="curr-header" onClick={() => togglePhase(0)}>
                <div className="curr-title-group">
                  <span className="curr-phase">PHASE 1</span>
                  <span className="curr-title">Ideas & Requirements Gathering</span>
                </div>
                <span className="curr-arrow">▼</span>
              </div>
              <div className="curr-body">
                <div className="curr-content">
                  Learn how to define project scopes and architect standard fintech flows before writing any code.
                  <ul>
                    <li>Translating business logic into system use cases</li>
                    <li>Structuring secure API payload schemas</li>
                    <li>Choosing the right cloud/backend integrations</li>
                  </ul>
                </div>
              </div>
            </div>

            {/* ITEM 2 */}
            <div className={`curr-item ${activePhase === 1 ? 'active' : ''}`}>
              <div className="curr-header" onClick={() => togglePhase(1)}>
                <div className="curr-title-group">
                  <span className="curr-phase">PHASE 2</span>
                  <span className="curr-title">Design Systems & UI Prototyping</span>
                </div>
                <span className="curr-arrow">▼</span>
              </div>
              <div className="curr-body">
                <div className="curr-content">
                  Create gorgeous, premium user interfaces that wow clients at first glance.
                  <ul>
                    <li>Vibrant Forest Green & Lime brand design tokens</li>
                    <li>Implementing custom curves, animations, and glassmorphism elements</li>
                    <li>Configuring transparent launcher icons across Android, iOS, Web, and Windows</li>
                  </ul>
                </div>
              </div>
            </div>

            {/* ITEM 3 */}
            <div className={`curr-item ${activePhase === 2 ? 'active' : ''}`}>
              <div className="curr-header" onClick={() => togglePhase(2)}>
                <div className="curr-title-group">
                  <span className="curr-phase">PHASE 3</span>
                  <span className="curr-title">Clean Architecture Restructuring</span>
                </div>
                <span className="curr-arrow">▼</span>
              </div>
              <div className="curr-body">
                <div className="curr-content">
                  Take a coupled codebase and refactor it into clean, loosely coupled modules.
                  <ul>
                    <li>Scaffolding Domain Entities, Repositories, and Use Cases</li>
                    <li>Setting up Data Sources and Model mappings</li>
                    <li>GetIt Service Locator and constructor dependency injection</li>
                  </ul>
                </div>
              </div>
            </div>

            {/* ITEM 4 */}
            <div className={`curr-item ${activePhase === 3 ? 'active' : ''}`}>
              <div className="curr-header" onClick={() => togglePhase(3)}>
                <div className="curr-title-group">
                  <span className="curr-phase">PHASE 4</span>
                  <span className="curr-title">Supabase & Utility Integrations</span>
                </div>
                <span className="curr-arrow">▼</span>
              </div>
              <div className="curr-body">
                <div className="curr-content">
                  Connect external services and manage state reactively.
                  <ul>
                    <li>Native Google OAuth / account picker login & signout</li>
                    <li>Monnify Wema virtual account creation & balance synchronization</li>
                    <li>VTPass real-time airtime, internet data, electricity, and cable TV settlements</li>
                  </ul>
                </div>
              </div>
            </div>

            {/* ITEM 5 */}
            <div className={`curr-item ${activePhase === 4 ? 'active' : ''}`}>
              <div className="curr-header" onClick={() => togglePhase(4)}>
                <div className="curr-title-group">
                  <span className="curr-phase">PHASE 5</span>
                  <span className="curr-title">Testing, CI/CD, & Hosting</span>
                </div>
                <span className="curr-arrow">▼</span>
              </div>
              <div className="curr-body">
                <div className="curr-content">
                  Write test assertions, deploy, and host your landing page and app.
                  <ul>
                    <li>Writing mocktail unit tests and resolving asynchronous test assertions</li>
                    <li>Compiling production APKs with release signatures</li>
                    <li>Deploying landing pages to GitHub Pages</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* DEMO / CAROUSEL SECTION */}
      <section className="arch" id="demo">
        <div className="section-container">
          <div className="section-header">
            <span className="section-subtitle">SEE IT IN ACTION</span>
            <h2 className="section-title">Watch the Demo & Download the App</h2>
          </div>

          <div className="carousel-viewport">
            {slides.map((slide, index) => (
              <div
                key={index}
                className={`carousel-slide ${currentSlide === index ? 'active' : ''}`}
              >
                <div className="carousel-video-mock">
                  <video
                    src={slide.video}
                    poster={slide.image}
                    controls
                    className="carousel-video-player"
                    style={{
                      width: '100%',
                      height: '100%',
                      objectFit: 'cover',
                      outline: 'none',
                      backgroundColor: '#000',
                    }}
                  />
                  <div className="carousel-slide-caption" style={{ pointerEvents: 'none', background: 'linear-gradient(transparent, rgba(0, 0, 0, 0.8))' }}>
                    <h4>{slide.title}</h4>
                    <p>{slide.description}</p>
                  </div>
                </div>
              </div>
            ))}

            <button className="carousel-control carousel-control-prev" onClick={handlePrevSlide}>◀</button>
            <button className="carousel-control carousel-control-next" onClick={handleNextSlide}>▶</button>
          </div>

          <div style={{ textAlign: 'center', marginTop: '48px' }}>
            <h3 style={{ fontSize: '24px', marginBottom: '16px' }}>Test the App on Your Phone</h3>
            <p style={{ color: 'var(--text-grey)', maxWidth: '600px', margin: '0 auto 24px' }}>
              Download the compiled Pay Lenses Android debug APK directly to test the Google Sign-In flow, virtual wallet simulation, and bill payments.
            </p>
            <a href="./PayLense.apk" download="PayLense.apk" className="btn btn-primary">
              📥 Download Android APK (Release)
            </a>
          </div>
        </div>
      </section>

      {/* FOOTER */}
      <footer>
        <div className="footer-logo">
          PAY LENSES<span className="logo-dot"></span>
        </div>
        <div className="footer-links">
          <a href="#features">Features</a>
          <a href="#architecture">Architecture</a>
          <a href="#curriculum">Curriculum</a>
          <a href="#demo">Download APK</a>
        </div>
        <p className="footer-copy">
          © 2026 Pay Lenses Masterclass. All rights reserved. Built with React and hosted on GitHub Pages.
        </p>
      </footer>
    </>
  );
}

export default App;
