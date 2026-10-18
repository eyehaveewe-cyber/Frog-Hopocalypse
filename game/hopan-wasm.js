/* Decode raw-gzip hosting responses as a stream, without buffering the 40 MB engine. */
(() => {
  'use strict';
  const originalFetch = window.fetch.bind(window);
  window.fetch = async (input, init) => {
    const response = await originalFetch(input, init);
    const url = new URL(typeof input === 'string' || input instanceof URL ? input : input.url, location.href);
    const enginePath = new URL('index.wasm', location.href).pathname;
    if (url.origin !== location.origin || url.pathname !== enginePath || !response.ok || !response.body) return response;
    const reader = response.body.getReader();
    const prefix = [];
    let size = 0;
    while (size < 2) {
      const part = await reader.read();
      if (part.done) break;
      prefix.push(part.value);
      size += part.value.length;
    }
    const signature = prefix.length ? (prefix[0].length >= 2 ? prefix[0] : new Uint8Array(prefix.flatMap(p => Array.from(p)))) : [];
    let body = new ReadableStream({
      start(controller) { for (const part of prefix) controller.enqueue(part); },
      async pull(controller) {
        try {
          const part = await reader.read();
          if (part.done) controller.close(); else controller.enqueue(part.value);
        } catch (error) { controller.error(error); }
      },
      cancel(reason) { return reader.cancel(reason); }
    });
    if (signature[0] === 0x1f && signature[1] === 0x8b) {
      if (typeof DecompressionStream !== 'function') {
        await reader.cancel();
        throw new Error('This browser cannot unpack the game. Open this address in an up-to-date Chrome or Firefox browser.');
      }
      body = body.pipeThrough(new DecompressionStream('gzip'));
    }
    const headers = new Headers(response.headers);
    headers.delete('Content-Encoding');
    headers.delete('Content-Length');
    headers.set('Content-Type', 'application/wasm');
    return new Response(body, {status: response.status, statusText: response.statusText, headers});
  };
})();
