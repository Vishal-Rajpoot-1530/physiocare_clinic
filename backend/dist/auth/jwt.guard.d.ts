import { CanActivate, ExecutionContext } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
export declare class JwtGuard implements CanActivate {
    private jwt;
    private p;
    constructor(jwt: JwtService, p: PrismaService);
    canActivate(c: ExecutionContext): Promise<boolean>;
}
