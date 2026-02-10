<script lang="ts">
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';

  let password = '';
  let error = '';
  let loading = false;

  onMount(() => {
    // Check if already authenticated
    const authToken = localStorage.getItem('authToken');
    const authTime = localStorage.getItem('authTime');
    
    if (authToken && authTime) {
      const elapsed = Date.now() - parseInt(authTime);
      // Token valid for 24 hours
      if (elapsed < 24 * 60 * 60 * 1000) {
        goto('/');
        return;
      }
    }
    
    // Clear expired auth
    localStorage.removeItem('authToken');
    localStorage.removeItem('authTime');
  });

  async function login() {
    if (!password) {
      error = 'Please enter password';
      return;
    }

    loading = true;
    error = '';

    try {
      // Call server API for authentication (using env variable)
      const API_BASE = import.meta.env.VITE_API_BASE;
      const response = await fetch(`${API_BASE}/api/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ password }),
      });

      const data = await response.json();

      if (response.ok && data.success) {
        // Save token from server
        localStorage.setItem('authToken', data.token);
        localStorage.setItem('authTime', Date.now().toString());
        
        // Redirect to home
        await goto('/');
      } else {
        error = data.message || 'Invalid password. Please try again.';
        password = '';
      }
    } catch (e) {
      console.error('Login error:', e);
      error = 'Unable to connect to server. Please try again.';
    } finally {
      loading = false;
    }
  }

  function handleKeyPress(e: KeyboardEvent) {
    if (e.key === 'Enter') {
      login();
    }
  }
</script>

<svelte:head>
  <title>Login - Remote Terminal</title>
</svelte:head>

<div class="login-container">
  <div class="login-box">
    <div class="logo">
      <div class="terminal-icon">
        <div class="terminal-line"></div>
        <div class="terminal-line"></div>
        <div class="terminal-line"></div>
      </div>
    </div>
    
    <h1 class="title">Remote Terminal</h1>
    <p class="subtitle">Secure collaborative terminal access</p>
    
    {#if error}
      <div class="error-message">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="10"></circle>
          <line x1="12" y1="8" x2="12" y2="12"></line>
          <line x1="12" y1="16" x2="12.01" y2="16"></line>
        </svg>
        {error}
      </div>
    {/if}

    <form on:submit|preventDefault={login} class="login-form">
      <div class="input-group">
        <label for="password">Password</label>
        <input 
          id="password"
          type="password" 
          bind:value={password}
          on:keypress={handleKeyPress}
          placeholder="Enter your password"
          disabled={loading}
          autocomplete="current-password"
        />
      </div>
      
      <button 
        type="submit"
        class="login-button"
        disabled={loading}
      >
        {#if loading}
          <span class="spinner"></span>
          Signing in...
        {:else}
          Sign In
        {/if}
      </button>
    </form>

    <div class="footer">
      <p class="hint">Default password: <code>titeo123</code></p>
    </div>
  </div>
</div>

<style>
  :global(body) {
    margin: 0;
    padding: 0;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  }

  .login-container {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    padding: 20px;
    position: relative;
    overflow: hidden;
  }

  .login-container::before {
    content: '';
    position: absolute;
    top: -50%;
    left: -50%;
    width: 200%;
    height: 200%;
    background: radial-gradient(circle, rgba(255,255,255,0.1) 1px, transparent 1px);
    background-size: 50px 50px;
    animation: drift 20s linear infinite;
  }

  @keyframes drift {
    0% { transform: translate(0, 0); }
    100% { transform: translate(50px, 50px); }
  }

  .login-box {
    background: rgba(255, 255, 255, 0.95);
    backdrop-filter: blur(10px);
    border-radius: 20px;
    padding: 40px;
    width: 100%;
    max-width: 420px;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
    position: relative;
    z-index: 1;
    animation: slideUp 0.5s ease-out;
  }

  @keyframes slideUp {
    from {
      opacity: 0;
      transform: translateY(30px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  .logo {
    display: flex;
    justify-content: center;
    margin-bottom: 20px;
  }

  .terminal-icon {
    width: 60px;
    height: 60px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border-radius: 12px;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    gap: 6px;
    padding: 15px;
    box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
  }

  .terminal-line {
    width: 100%;
    height: 3px;
    background: white;
    border-radius: 2px;
  }

  .terminal-line:nth-child(2) {
    width: 70%;
  }

  .terminal-line:nth-child(3) {
    width: 85%;
  }

  .title {
    font-size: 28px;
    font-weight: 700;
    color: #1a202c;
    text-align: center;
    margin: 0 0 8px 0;
  }

  .subtitle {
    font-size: 14px;
    color: #718096;
    text-align: center;
    margin: 0 0 30px 0;
  }

  .error-message {
    background: #fee;
    border: 1px solid #fcc;
    color: #c33;
    padding: 12px 16px;
    border-radius: 8px;
    margin-bottom: 20px;
    font-size: 14px;
    display: flex;
    align-items: center;
    gap: 10px;
    animation: shake 0.3s;
  }

  @keyframes shake {
    0%, 100% { transform: translateX(0); }
    25% { transform: translateX(-5px); }
    75% { transform: translateX(5px); }
  }

  .login-form {
    margin-bottom: 20px;
  }

  .input-group {
    margin-bottom: 20px;
  }

  .input-group label {
    display: block;
    font-size: 14px;
    font-weight: 600;
    color: #4a5568;
    margin-bottom: 8px;
  }

  .input-group input {
    width: 100%;
    padding: 12px 16px;
    font-size: 15px;
    border: 2px solid #e2e8f0;
    border-radius: 10px;
    background: white;
    color: #1a202c;
    transition: all 0.3s;
    box-sizing: border-box;
  }

  .input-group input:focus {
    outline: none;
    border-color: #667eea;
    box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
  }

  .input-group input:disabled {
    background: #f7fafc;
    cursor: not-allowed;
  }

  .login-button {
    width: 100%;
    padding: 14px;
    font-size: 16px;
    font-weight: 600;
    color: white;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border: none;
    border-radius: 10px;
    cursor: pointer;
    transition: all 0.3s;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
  }

  .login-button:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 10px 25px rgba(102, 126, 234, 0.4);
  }

  .login-button:active:not(:disabled) {
    transform: translateY(0);
  }

  .login-button:disabled {
    opacity: 0.7;
    cursor: not-allowed;
  }

  .spinner {
    width: 16px;
    height: 16px;
    border: 2px solid rgba(255, 255, 255, 0.3);
    border-top-color: white;
    border-radius: 50%;
    animation: spin 0.6s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .footer {
    text-align: center;
    padding-top: 20px;
    border-top: 1px solid #e2e8f0;
  }

  .hint {
    font-size: 13px;
    color: #718096;
    margin: 0;
  }

  .hint code {
    background: #f7fafc;
    padding: 2px 8px;
    border-radius: 4px;
    font-family: 'Monaco', 'Menlo', monospace;
    color: #667eea;
    font-weight: 600;
  }

  @media (max-width: 480px) {
    .login-box {
      padding: 30px 20px;
    }

    .title {
      font-size: 24px;
    }
  }
</style>
