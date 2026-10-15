import { PrismaService } from '../prisma/prisma.service';
export declare class MembersService {
    private p;
    constructor(p: PrismaService);
    all(adminId: bigint): Promise<{
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
    }[]>;
    one(adminId: bigint, id: string): Promise<{
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
    }>;
    key(adminId: bigint, code?: string, exceptId?: string): Promise<{
        taken: boolean;
    }>;
    private body;
    add(adminId: bigint, body: any): Promise<{
        id: number;
    }>;
    update(adminId: bigint, id: string, body: any): Promise<{
        success: boolean;
    }>;
    renew(adminId: bigint, id: string, body: any): Promise<{
        success: boolean;
    }>;
    adjustment(adminId: bigint, id: string, body: any): Promise<{
        success: boolean;
    }>;
    status(adminId: bigint, id: string, active: boolean): Promise<{
        success: boolean;
    }>;
    pr(adminId: bigint, id: string, kg: any): Promise<{
        success: boolean;
    }>;
    photo(adminId: bigint, id: string, file?: Express.Multer.File): Promise<{
        success: boolean;
    }>;
    del(adminId: bigint, id: string): Promise<{
        deleted: number;
    }>;
    clean(adminId: bigint): Promise<{
        deleted: number;
    }>;
    notes(adminId: bigint, id: string): Promise<{
        id: number;
        member_id: number;
        title: string;
        body: string;
        tags: string;
        created_at: string;
    }[]>;
    addNote(adminId: bigint, id: string, body: any): Promise<{
        success: boolean;
    }>;
}
