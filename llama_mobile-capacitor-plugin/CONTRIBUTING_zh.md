# 贡献指南

本指南提供了为这个Capacitor插件做出贡献的说明。

## 开发

### 本地设置

1. Fork并克隆仓库。
2. 安装依赖。

    ```shell
    npm install
    ```

3. 如果你在macOS上，请安装SwiftLint。

    ```shell
    brew install swiftlint
    ```

### 脚本

#### `npm run build`

构建插件的Web资源并使用[`@capacitor/docgen`](https://github.com/ionic-team/capacitor-docgen)生成插件API文档。

它会将`src/`目录下的TypeScript代码编译成`dist/esm/`目录下的ESM JavaScript文件。这些文件用于在使用打包器的应用中导入你的插件。

然后，Rollup会将代码打包成一个单独的文件`dist/plugin.js`。这个文件用于在不使用打包器的应用中，通过在`index.html`中包含脚本标签来使用。

#### `npm run verify`

构建并验证Web和原生项目。

这在CI中运行非常有用，可以验证插件是否能在所有平台上构建成功。

#### `npm run lint` / `npm run fmt`

检查格式和代码质量，如果可能的话自动格式化/修复。

这个模板集成了ESLint、Prettier和SwiftLint。使用这些工具是完全可选的，但[Capacitor社区](https://github.com/capacitor-community/)努力保持一致的代码风格和结构，以便于合作。

## 发布

`package.json`中有一个`prepublishOnly`钩子，它会在发布前准备插件，所以你只需要运行：

```shell
npm publish
```

> **注意**：`package.json`中的[`files`](https://docs.npmjs.com/cli/v7/configuring-npm/package-json#files)数组指定了哪些文件会被发布。如果你重命名文件/目录或在其他地方添加文件，你可能需要更新它。