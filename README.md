# Golconde HTTP请求发送器

Golconde 是一个用汇编语言编写的 HTTP 请求发送器，专为 x86_64 架构设计。它能够通过访问 localhost:8080 端口的 flag 文件来获取内容，并将该内容保存在本地的 flag 文件中。Golconde 被设计为在极端环境下使用的 HTTP 下载工具，适用于 curl、wget 等常见命令被禁用的情况。它可以从远端服务器拉取文件到本地，但由于当前版本的缓冲区没有实现循环处理，可能只适合接收较小的文件。此外，该程序目前还无法解析 DNS，因为在汇编语言中实现 DNS 解析存在一定的困难。目标 IP 和端口目前需要在源文件中修改后重新编译。理想情况下，它应该能够接收命令行参数来动态指定这些值。

## 编译方法

要编译 Golconde，您需要使用 nasm（Netwide Assembler）和 GNU 链接器。以下是编译 Golconde 的步骤：

```shell
nasm -f elf64 golconde.asm -o golconde.o
ld golconde.o -o golconde
```

由于 Golconde 设计用于特定情境，其使用场景可能受到限制，特别是在处理较大文件或需要 DNS 解析功能时。在未来的版本中可能会解决这些限制。

------

# Golconde HTTP Request Sender

Golconde is an HTTP request sender written in assembly language, designed specifically for the x86_64 architecture. It is capable of accessing content from a flag file located at localhost:8080 port and saving this content into a local flag file. Golconde is designed to be an HTTP download tool for use in extreme environments where common commands like curl and wget are disabled. It enables the retrieval of files from a remote server to the local system. However, due to the current version's buffer not implementing circular processing, it might only be suitable for receiving smaller files. Additionally, the program currently lacks DNS resolution capabilities, as implementing DNS resolution in assembly language presents certain challenges. Currently, the target IP and port need to be modified in the source file before recompilation. Ideally, it should accept command-line parameters to dynamically specify these values.

## Compilation Method

To compile Golconde, you need nasm (Netwide Assembler) and the GNU linker. Here are the steps to compile Golconde:

```shell
nasm -f elf64 golconde.asm -o golconde.o
ld golconde.o -o golconde
```

Given its design for specific scenarios, Golconde's applicability may be limited, especially when dealing with larger files or when DNS resolution functionality is required. Developers might address these limitations in future versions.
