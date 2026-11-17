(() => {
  if (window.__chatgptPiPExperiment) {
    window.__chatgptPiPExperiment.stop();
    return;
  }

  const W = 900, H = 1600, PAD = 42, LINE = 37;
  const canvas = document.createElement('canvas');
  canvas.width = W; canvas.height = H;
  const ctx = canvas.getContext('2d');
  const video = document.createElement('video');
  video.muted = true;
  video.playsInline = true;
  video.setAttribute('playsinline', '');
  video.style.cssText = 'position:fixed;width:2px;height:2px;opacity:.01;left:0;bottom:0;z-index:2147483646';
  document.body.appendChild(video);

  const control = document.createElement('button');
  control.textContent = 'Start ChatgptPiP';
  control.setAttribute('type', 'button');
  control.style.cssText = 'position:fixed;top:12px;right:12px;z-index:2147483647;padding:13px 17px;border:0;border-radius:12px;background:#2563eb;color:white;font:700 15px -apple-system,BlinkMacSystemFont,sans-serif;box-shadow:0 3px 14px #0008';
  document.body.appendChild(control);

  function wrap(text, maxWidth) {
    const words = String(text || '').replace(/\\s+/g, ' ').trim().split(' ');
    const lines = []; let line = '';
    for (const word of words) {
      const next = line ? line + ' ' + word : word;
      if (ctx.measureText(next).width > maxWidth && line) { lines.push(line); line = word; }
      else line = next;
    }
    if (line) lines.push(line);
    return lines;
  }

  function draw() {
    ctx.fillStyle = '#212121'; ctx.fillRect(0, 0, W, H);
    ctx.fillStyle = '#eeeeee'; ctx.font = 'bold 27px -apple-system, sans-serif';
    ctx.fillText('ChatGPT · live page view', PAD, 54);
    ctx.fillStyle = '#a8a8a8'; ctx.font = '18px -apple-system, sans-serif';
    ctx.fillText(new Date().toLocaleTimeString(), PAD, 85);
    let y = 132;
    const main = document.querySelector('main') || document.body;
    const nodes = [...main.querySelectorAll('[data-message-author-role], article')];
    const unique = [...new Set(nodes)].filter(el => !nodes.some(other => other !== el && other.contains(el)));
    const messages = unique.length ? unique : [main];
    for (const el of messages) {
      if (y > H - 110) break;
      const role = el.getAttribute('data-message-author-role') ||
        (el.querySelector('[data-message-author-role="assistant"]') ? 'assistant' : 'message');
      const text = (el.innerText || el.textContent || '').trim();
      if (!text) continue;
      const isUser = role === 'user';
      ctx.fillStyle = isUser ? '#303b50' : '#2b2b2b';
      const lines = wrap(text, W - PAD * 2 - 38).slice(0, 14);
      const height = Math.max(76, lines.length * LINE + 42);
      ctx.beginPath(); ctx.roundRect(PAD, y, W - PAD * 2, height, 18); ctx.fill();
      ctx.fillStyle = isUser ? '#a9c7ff' : '#a8d5b0';
      ctx.font = 'bold 20px -apple-system, sans-serif';
      ctx.fillText(isUser ? 'You' : 'ChatGPT', PAD + 20, y + 30);
      ctx.fillStyle = '#f1f1f1'; ctx.font = '22px -apple-system, sans-serif';
      lines.forEach((line, i) => ctx.fillText(line, PAD + 20, y + 64 + i * LINE));
      y += height + 22;
    }
    if (y <= 150) {
      ctx.fillStyle = '#ddd'; ctx.font = '22px -apple-system, sans-serif';
      ctx.fillText('No conversation messages detected yet.', PAD, y);
    }
  }

  draw();
  let stream;
  try {
    stream = canvas.captureStream(2);
  } catch (error) {
    control.textContent = 'Canvas video unavailable';
    control.disabled = true;
    alert('Safari could not create the live canvas video: ' + error.message);
    return;
  }
  video.srcObject = stream;
  const observer = new MutationObserver(() => draw());
  observer.observe(document.body, {subtree:true, childList:true, characterData:true});
  let stopped = false;
  const stop = () => {
    if (stopped) return;
    stopped = true;
    observer.disconnect();
    stream.getTracks().forEach(t => t.stop());
    video.pause(); video.srcObject = null; video.remove(); control.remove();
    delete window.__chatgptPiPExperiment;
  };
  window.__chatgptPiPExperiment = { stop };

  control.addEventListener('click', () => {
    try {
      // Both calls are made directly inside this tap so iOS receives a fresh
      // user gesture for playback and the PiP request.
      const playPromise = video.play();
      let pipPromise;
      if (video.requestPictureInPicture) pipPromise = video.requestPictureInPicture();
      else if (video.webkitSetPresentationMode) {
        video.webkitSetPresentationMode('picture-in-picture');
        pipPromise = Promise.resolve();
      } else {
        throw new Error('This Safari version does not expose video Picture-in-Picture.');
      }
      Promise.all([playPromise, pipPromise]).then(() => {
        control.textContent = 'PiP started · tap to stop';
      }).catch(error => {
        control.textContent = 'PiP failed · tap to retry';
        alert('Safari could not start PiP: ' + error.name + ' – ' + error.message);
      });
    } catch (error) {
      control.textContent = 'PiP failed · tap to retry';
      alert('ChatgptPiP could not start: ' + error.message);
    }
  });

  window.addEventListener('pagehide', stop, {once:true});
})();