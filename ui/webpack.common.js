const path = require('path');
const webpack = require('webpack');
const CleanWebpackPlugin = require('clean-webpack-plugin');
const HtmlWebpackPlugin = require('html-webpack-plugin');

const BASE_PATH = path.resolve(__dirname, '.');
const SRC_PATH = path.join(BASE_PATH, 'src');
const DIST_PATH = path.join(BASE_PATH, 'dist');

module.exports = {
    entry: path.join(SRC_PATH, 'main.js'),
    module: {
        rules: [
            {
                test: /\.elm$/,
                exclude: [/elm-stuff/, /node_modules/],
                use: ['elm-webpack-loader'],
            },
            {
                test: /\.scss$/,
                use: ['style-loader', 'css-loader', 'sass-loader']
            },
        ]
    },
    plugins: [
        new CleanWebpackPlugin,
        new HtmlWebpackPlugin({
            alwaysWriteToDisk: true,
            template: path.join(SRC_PATH, 'index.html'),
        })
    ],
    output: {
        filename: '[name].bundle.js',
        path: DIST_PATH,
        publicPath: '/dist/',
    },
    optimization: {
        splitChunks: {
            cacheGroups: {
                commons: {
                    test: /[\\/]node_modules[\\/]/,
                    name: 'vendors',
                    chunks: 'all'
                }
            }
        }
    }
};
