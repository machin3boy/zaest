const { defineConfig } = require('@vue/cli-service')
module.exports = defineConfig({
  transpileDependencies: true,
  configureWebpack: {
    devServer: {
      proxy: {
        '/': {
          target: 'http://localhost:3000',
        },
      },
    },
  },
})
