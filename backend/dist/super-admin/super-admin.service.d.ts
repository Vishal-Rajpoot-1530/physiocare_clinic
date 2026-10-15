import { PrismaService } from '../prisma/prisma.service';
declare const PLAN: {
    readonly monthly: {
        readonly months: 1;
        readonly price: 150;
    };
    readonly quarterly: {
        readonly months: 3;
        readonly price: 300;
    };
    readonly yearly: {
        readonly months: 12;
        readonly price: 1000;
    };
};
type PlanType = keyof typeof PLAN;
export declare class SuperAdminService {
    private p;
    constructor(p: PrismaService);
    private jsonUser;
    createUser(d: any): Promise<{
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
    updateUser(id: string, d: any): Promise<{
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
    resetPassword(id: string, password: string): Promise<{
        success: boolean;
        message: string;
    }>;
    setStatus(id: string, status: string): Promise<{
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
    assignOrRenew(id: string, planType: PlanType): Promise<{
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
