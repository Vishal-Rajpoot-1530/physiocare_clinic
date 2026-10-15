import { MembersService } from './members.service';
export declare class MembersController {
    private s;
    constructor(s: MembersService);
    all(r: any): Promise<{
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
    key(r: any, c: string, e?: string): Promise<{
        taken: boolean;
    }>;
    clean(r: any): Promise<{
        deleted: number;
    }>;
    one(r: any, id: string): Promise<{
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
    add(r: any, b: any): Promise<{
        id: number;
    }>;
    update(r: any, id: string, b: any): Promise<{
        success: boolean;
    }>;
    renew(r: any, id: string, b: any): Promise<{
        success: boolean;
    }>;
    adjustment(r: any, id: string, b: any): Promise<{
        success: boolean;
    }>;
    status(r: any, id: string, b: any): Promise<{
        success: boolean;
    }>;
    pr(r: any, id: string, b: any): Promise<{
        success: boolean;
    }>;
    photo(r: any, id: string, f: Express.Multer.File): Promise<{
        success: boolean;
    }>;
    del(r: any, id: string): Promise<{
        deleted: number;
    }>;
    notes(r: any, id: string): Promise<{
        id: number;
        member_id: number;
        title: string;
        body: string;
        tags: string;
        created_at: string;
    }[]>;
    addNote(r: any, id: string, b: any): Promise<{
        success: boolean;
    }>;
}
