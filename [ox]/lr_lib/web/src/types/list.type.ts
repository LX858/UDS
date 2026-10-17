export interface IListItem {
  key: string | number;
  value: string | number;
}

export interface IList {
  id: number;
  title: string;
  description?: string;
  elements: IListItem[];
}
