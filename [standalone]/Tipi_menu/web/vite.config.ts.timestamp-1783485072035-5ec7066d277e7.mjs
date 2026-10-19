// vite.config.ts
import path from "path";
import { defineConfig } from "file:///E:/Project/GTA5-UNDERSTAR/script/Menu/Tipi_menu/web/node_modules/vite/dist/node/index.js";
import react from "file:///E:/Project/GTA5-UNDERSTAR/script/Menu/Tipi_menu/web/node_modules/@vitejs/plugin-react/dist/index.mjs";
var __vite_injected_original_dirname = "E:\\Project\\GTA5-UNDERSTAR\\script\\Menu\\Tipi_menu\\web";
var tipiRankingsSrc = path.resolve(__vite_injected_original_dirname, "../../Tipi_Rankings/web/src");
var tipiDailyRewardsSrc = path.resolve(__vite_injected_original_dirname, "../../Tipi_Daily_Rewards/web/src");
var vite_config_default = defineConfig({
  plugins: [react()],
  base: "./",
  build: {
    outDir: "build",
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (id.includes("Tipi_Rankings/web/src")) {
            return "leaderboard";
          }
          if (id.includes("Tipi_Daily_Rewards/web/src")) {
            return "daily-rewards";
          }
        }
      }
    }
  },
  resolve: {
    alias: {
      "@": tipiRankingsSrc,
      "@tipi-rankings": tipiRankingsSrc,
      "@uls-lb": tipiRankingsSrc,
      "@tipi-daily-rewards": tipiDailyRewardsSrc
    }
  }
});
export {
  vite_config_default as default
};
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsidml0ZS5jb25maWcudHMiXSwKICAic291cmNlc0NvbnRlbnQiOiBbImNvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9kaXJuYW1lID0gXCJFOlxcXFxQcm9qZWN0XFxcXEdUQTUtVU5ERVJTVEFSXFxcXHNjcmlwdFxcXFxNZW51XFxcXFRpcGlfbWVudVxcXFx3ZWJcIjtjb25zdCBfX3ZpdGVfaW5qZWN0ZWRfb3JpZ2luYWxfZmlsZW5hbWUgPSBcIkU6XFxcXFByb2plY3RcXFxcR1RBNS1VTkRFUlNUQVJcXFxcc2NyaXB0XFxcXE1lbnVcXFxcVGlwaV9tZW51XFxcXHdlYlxcXFx2aXRlLmNvbmZpZy50c1wiO2NvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9pbXBvcnRfbWV0YV91cmwgPSBcImZpbGU6Ly8vRTovUHJvamVjdC9HVEE1LVVOREVSU1RBUi9zY3JpcHQvTWVudS9UaXBpX21lbnUvd2ViL3ZpdGUuY29uZmlnLnRzXCI7aW1wb3J0IHBhdGggZnJvbSAncGF0aCdcbmltcG9ydCB7IGRlZmluZUNvbmZpZyB9IGZyb20gJ3ZpdGUnXG5pbXBvcnQgcmVhY3QgZnJvbSAnQHZpdGVqcy9wbHVnaW4tcmVhY3QnXG5cbmNvbnN0IHRpcGlSYW5raW5nc1NyYyA9IHBhdGgucmVzb2x2ZShfX2Rpcm5hbWUsICcuLi8uLi9UaXBpX1JhbmtpbmdzL3dlYi9zcmMnKVxuY29uc3QgdGlwaURhaWx5UmV3YXJkc1NyYyA9IHBhdGgucmVzb2x2ZShfX2Rpcm5hbWUsICcuLi8uLi9UaXBpX0RhaWx5X1Jld2FyZHMvd2ViL3NyYycpXG5cbi8vIGh0dHBzOi8vdml0ZWpzLmRldi9jb25maWcvXG5leHBvcnQgZGVmYXVsdCBkZWZpbmVDb25maWcoe1xuXHRwbHVnaW5zOiBbcmVhY3QoKV0sXG5cdGJhc2U6ICcuLycsXG5cdGJ1aWxkOiB7XG5cdFx0b3V0RGlyOiAnYnVpbGQnLFxuXHRcdHJvbGx1cE9wdGlvbnM6IHtcblx0XHRcdG91dHB1dDoge1xuXHRcdFx0XHRtYW51YWxDaHVua3MoaWQpIHtcblx0XHRcdFx0XHRpZiAoaWQuaW5jbHVkZXMoJ1RpcGlfUmFua2luZ3Mvd2ViL3NyYycpKSB7XG5cdFx0XHRcdFx0XHRyZXR1cm4gJ2xlYWRlcmJvYXJkJ1xuXHRcdFx0XHRcdH1cblx0XHRcdFx0XHRpZiAoaWQuaW5jbHVkZXMoJ1RpcGlfRGFpbHlfUmV3YXJkcy93ZWIvc3JjJykpIHtcblx0XHRcdFx0XHRcdHJldHVybiAnZGFpbHktcmV3YXJkcydcblx0XHRcdFx0XHR9XG5cdFx0XHRcdH0sXG5cdFx0XHR9LFxuXHRcdH0sXG5cdH0sXG5cdHJlc29sdmU6IHtcblx0XHRhbGlhczoge1xuXHRcdFx0J0AnOiB0aXBpUmFua2luZ3NTcmMsXG5cdFx0XHQnQHRpcGktcmFua2luZ3MnOiB0aXBpUmFua2luZ3NTcmMsXG5cdFx0XHQnQHVscy1sYic6IHRpcGlSYW5raW5nc1NyYyxcblx0XHRcdCdAdGlwaS1kYWlseS1yZXdhcmRzJzogdGlwaURhaWx5UmV3YXJkc1NyYyxcblx0XHR9LFxuXHR9LFxufSlcbiJdLAogICJtYXBwaW5ncyI6ICI7QUFBeVYsT0FBTyxVQUFVO0FBQzFXLFNBQVMsb0JBQW9CO0FBQzdCLE9BQU8sV0FBVztBQUZsQixJQUFNLG1DQUFtQztBQUl6QyxJQUFNLGtCQUFrQixLQUFLLFFBQVEsa0NBQVcsNkJBQTZCO0FBQzdFLElBQU0sc0JBQXNCLEtBQUssUUFBUSxrQ0FBVyxrQ0FBa0M7QUFHdEYsSUFBTyxzQkFBUSxhQUFhO0FBQUEsRUFDM0IsU0FBUyxDQUFDLE1BQU0sQ0FBQztBQUFBLEVBQ2pCLE1BQU07QUFBQSxFQUNOLE9BQU87QUFBQSxJQUNOLFFBQVE7QUFBQSxJQUNSLGVBQWU7QUFBQSxNQUNkLFFBQVE7QUFBQSxRQUNQLGFBQWEsSUFBSTtBQUNoQixjQUFJLEdBQUcsU0FBUyx1QkFBdUIsR0FBRztBQUN6QyxtQkFBTztBQUFBLFVBQ1I7QUFDQSxjQUFJLEdBQUcsU0FBUyw0QkFBNEIsR0FBRztBQUM5QyxtQkFBTztBQUFBLFVBQ1I7QUFBQSxRQUNEO0FBQUEsTUFDRDtBQUFBLElBQ0Q7QUFBQSxFQUNEO0FBQUEsRUFDQSxTQUFTO0FBQUEsSUFDUixPQUFPO0FBQUEsTUFDTixLQUFLO0FBQUEsTUFDTCxrQkFBa0I7QUFBQSxNQUNsQixXQUFXO0FBQUEsTUFDWCx1QkFBdUI7QUFBQSxJQUN4QjtBQUFBLEVBQ0Q7QUFDRCxDQUFDOyIsCiAgIm5hbWVzIjogW10KfQo=
