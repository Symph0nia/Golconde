section .data
    httpRequest db "GET /wget HTTP/1.1",0xD,0xA
                db "Host: %s:%s",0xD,0xA
                db "Connection: close",0xD,0xA,0xD,0xA
    fileName db "wget",0
    usage_msg db "Usage: %s <ip> <port>",0xA,0
    error_ip db "Invalid IP address",0xA,0
    error_port db "Invalid port number",0xA,0

section .bss
    sockaddr resb 16
    recvBuffer resb 16384
    fd resb 4
    ip_str resb 16        ; IP地址缓冲区
    port_str resb 6       ; 端口缓冲区
    formatted_request resb 512  ; 格式化后的HTTP请求缓冲区

section .text
global _start

_start:
    ; 检查命令行参数
    pop rax         ; 获取参数个数
    cmp rax, 3      ; 需要3个参数
    jne usage_error

    pop rax         ; 程序名
    pop rax         ; IP地址
    mov r14, rax    ; 保存IP地址
    pop rax         ; 端口
    mov r15, rax    ; 保存端口

    ; 复制IP和端口到缓冲区
    mov rsi, r14
    mov rdi, ip_str
    call strcpy

    mov rsi, r15
    mov rdi, port_str
    call strcpy

    ; 检查端口号有效性
    mov rdi, port_str
    call validate_port
    test rax, rax
    jz port_error

    ; 检查IP地址有效性
    mov rdi, ip_str
    call validate_ip
    test rax, rax
    jz ip_error

    ; 创建socket
    mov rax, 41     ; socket syscall
    mov rdi, 2      ; AF_INET
    mov rsi, 1      ; SOCK_STREAM
    xor rdx, rdx    ; 0
    syscall
    mov r12, rax    ; 保存socket fd

    ; 设置sockaddr结构
    mov word [sockaddr], 2     ; AF_INET
    
    ; 转换端口号
    mov rdi, port_str
    call atoi
    xchg al, ah              ; 转换为网络字节序
    mov word [sockaddr+2], ax ; 设置端口

    ; 转换IP地址
    mov rdi, ip_str
    mov rsi, sockaddr+4
    call inet_pton

    xor rax, rax
    mov qword [sockaddr+8], rax

    ; 连接到服务器
    mov rax, 42              ; connect syscall
    mov rdi, r12            ; socket fd
    mov rsi, sockaddr       ; struct sockaddr *
    mov rdx, 16             ; addrlen
    syscall

    ; 发送HTTP请求
    mov rax, 44             ; sendto syscall
    mov rdi, r12           ; socket fd
    mov rsi, httpRequest   ; message
    mov rdx, 512           ; length
    xor r10, r10          ; flags
    xor r8, r8            ; dest_addr
    xor r9, r9            ; addrlen
    syscall

    ; 打开文件准备写入
    mov rax, 2            ; open syscall
    mov rdi, fileName     ; filename
    mov rsi, 0102o       ; O_CREAT|O_WRONLY
    mov rdx, 0644o       ; mode
    syscall
    mov r13, rax         ; 保存文件fd

    xor r14, r14         ; r14用于标记是否找到header

read_loop:
    mov rax, 0           ; read syscall
    mov rdi, r12         ; socket fd
    mov rsi, recvBuffer  ; buffer
    mov rdx, 16384       ; count
    syscall

    test rax, rax
    jle cleanup

    mov r15, rax         ; 保存读取的长度

    test r14, r14
    jnz write_data

find_header:
    mov rcx, recvBuffer
    mov rdx, rcx
    add rdx, r15

next_byte:
    cmp rcx, rdx
    jge read_loop
    cmp dword [rcx], 0x0A0D0A0D
    je header_found
    inc rcx
    jmp next_byte

header_found:
    mov r14, 1
    add rcx, 4
    mov rsi, rcx
    mov rdx, recvBuffer
    add rdx, r15
    sub rdx, rcx
    jmp write_file

write_data:
    mov rsi, recvBuffer
    mov rdx, r15

write_file:
    mov rax, 1          ; write syscall
    mov rdi, r13        ; file fd
    syscall
    jmp read_loop

cleanup:
    mov rax, 3          ; close syscall
    mov rdi, r13        ; file fd
    syscall

    mov rax, 3          ; close syscall
    mov rdi, r12        ; socket fd
    syscall

    mov rax, 60         ; exit syscall
    xor rdi, rdi
    syscall

usage_error:
    mov rdi, 1
    mov rsi, usage_msg
    mov rdx, 26
    mov rax, 1          ; write syscall
    syscall
    mov rax, 60         ; exit syscall
    mov rdi, 1
    syscall

ip_error:
    mov rdi, 1
    mov rsi, error_ip
    mov rdx, 18
    mov rax, 1          ; write syscall
    syscall
    mov rax, 60         ; exit syscall
    mov rdi, 1
    syscall

port_error:
    mov rdi, 1
    mov rsi, error_port
    mov rdx, 19
    mov rax, 1          ; write syscall
    syscall
    mov rax, 60         ; exit syscall
    mov rdi, 1
    syscall

; 辅助函数
strcpy:                 ; rdi = destination, rsi = source
    xor rcx, rcx
.loop:
    mov al, [rsi + rcx]
    mov [rdi + rcx], al
    inc rcx
    test al, al
    jnz .loop
    ret

atoi:                   ; rdi = string
    xor rax, rax
    xor rcx, rcx
.loop:
    movzx rdx, byte [rdi + rcx]
    test rdx, rdx
    jz .done
    sub rdx, '0'
    imul rax, 10
    add rax, rdx
    inc rcx
    jmp .loop
.done:
    ret

inet_pton:              ; rdi = IP string, rsi = destination
    xor rax, rax
    xor rcx, rcx
    xor rdx, rdx
.loop:
    movzx r8, byte [rdi + rcx]
    test r8, r8
    jz .done
    cmp r8, '.'
    je .next_octet
    sub r8, '0'
    imul rdx, 10
    add rdx, r8
    inc rcx
    jmp .loop
.next_octet:
    mov byte [rsi], dl
    inc rsi
    xor rdx, rdx
    inc rcx
    jmp .loop
.done:
    mov byte [rsi], dl
    ret

validate_port:          ; rdi = port string
    xor rax, rax
    xor rcx, rcx
    xor rdx, rdx
.loop:
    movzx r8, byte [rdi + rcx]
    test r8, r8
    jz .check_value
    sub r8, '0'
    cmp r8, 9
    ja .error
    imul rdx, 10
    add rdx, r8
    inc rcx
    jmp .loop
.check_value:
    cmp rdx, 65535
    ja .error
    mov rax, 1
    ret
.error:
    xor rax, rax
    ret

validate_ip:            ; rdi = IP string
    xor rax, rax
    xor rcx, rcx
    xor rdx, rdx
    mov r9, 0          ; 点的数量
.loop:
    movzx r8, byte [rdi + rcx]
    test r8, r8
    jz .check_dots
    cmp r8, '.'
    je .check_octet
    sub r8, '0'
    cmp r8, 9
    ja .error
    imul rdx, 10
    add rdx, r8
    inc rcx
    jmp .loop
.check_octet:
    cmp rdx, 255
    ja .error
    inc r9
    xor rdx, rdx
    inc rcx
    jmp .loop
.check_dots:
    cmp r9, 3
    jne .error
    cmp rdx, 255
    ja .error
    mov rax, 1
    ret
.error:
    xor rax, rax
    ret