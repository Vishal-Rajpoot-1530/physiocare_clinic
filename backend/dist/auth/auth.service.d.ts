import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
export declare class AuthService {
    private p;
    private jwt;
    constructor(p: PrismaService, jwt: JwtService);
    register(d: any): Promise<{
        success: boolean;
    }>;
    login(d: any): Promise<{
        token: string;
        user: {
            subscription?: {
                plan_type: any;
                start_date: any;
                expiry_date: any;
                status: any;
            } | undefined;
            id: number;
            name: string;
            email: string;
            phone: string;
            type: string;
            status: string;
        };
    }>;
    getProfile(adminId: bigint): Promise<{
        id: number;
        name: string;
        email: string;
        phone: string;
        type: string;
        status: string;
        created_at: string;
    }>;
    updateProfile(adminId: bigint, name: string): Promise<{
        id: number;
        name: string;
        email: string;
        phone: string;
        type: string;
        status: string;
        created_at: string;
    }>;
    changePassword(adminId: bigint, currentPassword: string, newPassword: string): Promise<{
        success: boolean;
    }>;
}
