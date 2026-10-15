import { PrismaService } from '../prisma/prisma.service';
export declare class CheckinsController {
    private p;
    constructor(p: PrismaService);
    find(r: any, raw?: string): Promise<{
        id: number;
        name: any;
        email: any;
        phone: any;
        gender: any;
        age: any;
        plan: any;
        duration_value: any;
        duration_unit: any;
        fee: number;
        joining_date: string | null;
        expiry_date: string | null;
        status: any;
        notes: any;
        keycard: any;
        pr_kg: number;
        photo: string | null;
        created_at: string | null;
    } | null>;
    add(r: any, id: string): Promise<{
        created: boolean;
    }>;
    today(r: any): Promise<{
        at: string;
        name: string;
        id: number;
    }[]>;
    stats(r: any, id: string): Promise<{
        total: number;
        streak: number;
    }>;
}
