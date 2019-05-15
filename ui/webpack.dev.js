const path = require('path');
const merge = require('webpack-merge');
const common = require('./webpack.common.js');
const HtmlWebpackHarddiskPlugin = require('html-webpack-harddisk-plugin');


module.exports = merge(common, {
    mode: 'development',
    devtool: 'inline-source-map',
    output: {
        filename: 'js/[name].js',
    },
    plugins: [
        new HtmlWebpackHarddiskPlugin,
    ],
    devServer: {
        stats: 'minimal',
        contentBase: path.resolve(__dirname, 'dist'),
        publicPath: '/dist/',
        proxy: {}
    }
});
