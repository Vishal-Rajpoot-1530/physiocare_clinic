import { SuperAdminService } from './super-admin.service';
declare class CreateUserDto {
    name: string;
    phone: string;
    email: string;
    password: string;
    type: string;
}
declare class UpdateUserDto {
    name?: string;
    phone?: string;
    email?: string;
    type?: string;
}
declare class ResetPasswordDto {
    password: string;
}
declare class StatusDto {
    status: string;
}
declare class SubscriptionDto {
    planType: 'monthly' | 'quarterly' | 'yearly';
}
export declare class SuperAdminController {
    private s;
    constructor(s: SuperAdminService);
    create(d: CreateUserDto): Promise<{
        id: number;
        name: any;
        phone: any;
        email: any;
        type: any;
        status: any;
        created_at: any;
        subscription: {
            id: number;
            plan_type: any;
            price: number;
            start_date: any;
            expiry_date: any;
            status: any;
        } | null;
    }>;
    users(): Promise<{
        id: number;
        name: any;
        phone: any;
        email: any;
        type: any;
        status: any;
        created_at: any;
        subscription: {
            id: number;
            plan_type: any;
            price: number;
            start_date: any;
            expiry_date: any;
            status: any;
        } | null;
    }[]>;
    update(id: string, d: UpdateUserDto): Promise<{
        id: number;
        name: any;
        phone: any;
        email: any;
        type: any;
        status: any;
        created_at: any;
        subscription: {
            id: number;
            plan_type: any;
            price: number;
            start_date: any;
            expiry_date: any;
            status: any;
        } | null;
    }>;
    resetPassword(id: string, d: ResetPasswordDto): Promise<{
        success: boolean;
        message: string;
    }>;
    status(id: string, d: StatusDto): Promise<{
        id: number;
        name: any;
        phone: any;
        email: any;
        type: any;
        status: any;
        created_at: any;
        subscription: {
            id: number;
            plan_type: any;
            price: number;
            start_date: any;
            expiry_date: any;
            status: any;
        } | null;
    }>;
    subscription(id: string, d: SubscriptionDto): Promise<{
        id: number;
        name: any;
        phone: any;
        email: any;
        type: any;
        status: any;
        created_at: any;
        subscription: {
            id: number;
            plan_type: any;
            price: number;
            start_date: any;
            expiry_date: any;
            status: any;
        } | null;
    }>;
    renew(id: string, d: SubscriptionDto): Promise<{
        id: number;
        name: any;
        phone: any;
        email: any;
        type: any;
        status: any;
        created_at: any;
        subscription: {
            id: number;
            plan_type: any;
            price: number;
            start_date: any;
            expiry_date: any;
            status: any;
        } | null;
    }>;
}
export {};
