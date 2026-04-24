{ ... }:

{
  services.redis.servers.main = {
    enable = true;
    bind = "127.0.0.1";
    port = 6379;
    save = [ [ 3600 1 ] [ 300 100 ] [ 60 10000 ] ];
    settings = {
      maxmemory = "256mb";
      maxmemory-policy = "allkeys-lru";
    };
  };
}
