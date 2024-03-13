section .data
    httpRequest db "GET /flag HTTP/1.1", 0xA
                 db "Host: localhost", 0xA
                 db "Connection: close", 0xA, 0xA
    requestLen equ $-httpRequest
    fileName db "flag", 0

section .bss
    sockaddr resb 16
    recvBuffer resb 8192
    fileDescriptor resb 4

section .text
global _start

_start:

    mov rax, 2
    mov rdi, fileName
    mov rsi, 0101O
    mov rdx, 0644
    syscall
    mov [fileDescriptor], eax
    
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    xor rdx, rdx
    syscall
    mov rdi, rax

    mov word [sockaddr], 2
    mov word [sockaddr+2], 0x901f
    mov dword [sockaddr+4], 0x0100007F
    xor rax, rax
    mov qword [sockaddr+8], rax

    mov rax, 42
    mov rsi, sockaddr
    mov rdx, 16
    syscall

    mov rax, 44
    mov rsi, httpRequest
    mov rdx, requestLen
    xor r10, r10
    xor r8, r8
    xor r9, r9
    syscall

    mov rax, 0
    mov rdi, rdi
    mov rsi, recvBuffer
    mov rdx, 8192
    syscall

    cmp rax, 0
    je closeSocket

    mov rdi, recvBuffer
    add rdi, rax
    sub rdi, 4
    mov rcx, recvBuffer
    
findCRLF:
    cmp rcx, rdi
    jge printBody
    mov al, [rcx]
    cmp al, 0x0D
    jne incrementPointer
    mov al, [rcx+1]
    cmp al, 0x0A
    jne incrementPointer
    mov al, [rcx+2]
    cmp al, 0x0D
    jne incrementPointer
    mov al, [rcx+3]
    cmp al, 0x0A
    je preparePrint

incrementPointer:
    inc rcx
    jmp findCRLF

preparePrint:
    add rcx, 4

printBody:
    mov rax, 1
    mov rdi, [fileDescriptor]
    mov rsi, rcx
    mov rdx, recvBuffer
    add rdx, 8192
    sub rdx, rsi
    syscall

    mov rax, 3
    mov rdi, [fileDescriptor]
    syscall

closeSocket:
    mov rax, 3
    mov rdi, [sockaddr]
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall