# tsoding's zoomer for x11, from the fork that has a nim lock file
{
  lib,
  buildNimPackage,
  fetchFromGitHub,
  libGL,
  libGLU,
  libx11,
  libxext,
  libxrandr,
}:

buildNimPackage {
  pname = "boomer";
  version = "0-unstable-2025-01-23";

  src = fetchFromGitHub {
    owner = "nilp0inter";
    repo = "boomer";
    rev = "3c1917956ac40de94a86d471202c968e4a93c3dd";
    hash = "sha256-Bf4DEcyU/5kjIRS4Yo8MnNfAItBXzH9/cCufQcyqTBE=";
  };

  # a copy of the one in src, so evaluating needs no download
  lockFile = ./lock.json;

  propagatedBuildInputs = [
    libGL
    libGLU
    libx11
    libxext
    libxrandr
  ];

  meta = {
    description = "Zoomer application for Linux";
    homepage = "https://github.com/tsoding/boomer";
    license = lib.licenses.mit;
    mainProgram = "boomer";
    platforms = lib.platforms.linux;
  };
}
