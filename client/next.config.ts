import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
  reactStrictMode: true,
  async rewrites() {
    return [
      {
        source: "/api/:path*",
        // BACKEND_URL задається на етапі збірки (docker compose: http://backend:8080,
        // Kubernetes: http://backend-service:8080)
        destination: `${process.env.BACKEND_URL ?? "http://backend-service:8080"}/api/:path*`,
      },
    ];
  },
  images: {
    domains: ["jawg.io"], // Add any image domains you're using
    formats: ["image/avif", "image/webp"],
  },
  compiler: {
    removeConsole: process.env.NODE_ENV === "production",
  },
  experimental: {
    optimizeCss: true,
    serverActions: {
      allowedOrigins: ["localhost:3000"],
    },
  },
};

export default nextConfig;
