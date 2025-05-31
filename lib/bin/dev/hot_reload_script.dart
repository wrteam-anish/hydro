const String injectableScript = """<script>
  const socket = new WebSocket('ws://localhost:4040');
  socket.onmessage = (event) => {
    if (event.data === 'reload') {
      console.log('Reload message received, reloading page...');
      window.location.reload();
    }
  };
  socket.onclose = () => {
    console.log('WebSocket connection closed');
  };
</script>
""";
