import { AuthService } from './auth.service';
declare class RegisterDto {
    name: string;
    email: string;
    phone?: string;
    type?: string;
    password: string;
}
declare class LoginDto {
    email: string;
    password: string;
}
declare class UpdateProfileDto {
    name: string;
}
declare class ChangePasswordDto {
    currentPassword: string;
    newPassword: string;
}
export declare class AuthController {
    private s;
    constructor(s: AuthService);
    register(d: RegisterDto): Promise<{
        success: boolean;
    }>;
    login(d: LoginDto): Promise<{
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
    profile(r: any): Promise<{
        id: number;
        name: string;
        email: string;
        phone: string;
        type: string;
        status: string;
        created_at: string;
    }>;
    updateProfile(r: any, d: UpdateProfileDto): Promise<{
        id: number;
        name: string;
        email: string;
        phone: string;
        type: string;
        status: string;
        created_at: string;
    }>;
    changePassword(r: any, d: ChangePasswordDto): Promise<{
        success: boolean;
    }>;
}
export {};
