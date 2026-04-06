{...}: {
  programs.yt-dlp = {
    enable = true;
    settings = {
      format = "bestvideo[height<=1080]+bestaudio/best[height<=1080]";

      downloader = "aria2c";
      downloader-args = "aria2c:'-c -x8 -s8 -k1M'";

      audio-quality = "0";
    };
  };
}
