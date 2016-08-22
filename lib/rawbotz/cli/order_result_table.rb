module Rawbotz::CLI
  module OrderResultTable
    def self.tables diffs
      out = ""
      if !diffs[:error].empty?
        error_items = diffs[:error].map do |p|
          [p[0][0..35]]
        end
        out << Terminal::Table.new(title: "With error",
          headings: ['Product'],
          rows:     error_items,
          style:    {width: 60}).to_s
        out << "\n\n"
      end

      if !diffs[:perfect].empty?
        perfect_items = diffs[:perfect].map do |p, q|
          [p.local_product.remote_product.name[0..35], q]
        end
        out << Terminal::Table.new(title: "Perfect",
          headings: ['Product', 'In Cart'],
          rows:     perfect_items,
          style:    {width: 60}).to_s
        out << "\n\n"
      end

      if !diffs[:modified].empty?
        modified_items = diffs[:modified].map do |p,q|
          [p.local_product.remote_product.name[0..35], p.num_wished, q]
        end
        out << Terminal::Table.new(title: "Modified",
          headings: ['Product', 'Wished', 'In Cart'],
          rows:     modified_items,
          style:    {width:60}).to_s
        out << "\n\n"
      end

      if !diffs[:miss].empty?
        missing_items = diffs[:miss].map do |p,q|
          [p.local_product.remote_product.name[0..35], q]
        end
        out << Terminal::Table.new(title: "Missing (?)",
          headings: ['Product', 'In Cart'],
          rows:     missing_items,
          style:    {width:60}).to_s
        out << "\n\n"
      end

      if !diffs[:under_avail].empty?
        under_avail_items = diffs[:under_avail].map do |p,q|
          [p.local_product.remote_product.name[0..35], p.num_wished, q]
        end
        out << Terminal::Table.new(title: "Not available as such",
          headings: ['Product', 'Wanted', 'In Cart'],
          rows:     under_avail_items,
          style:    {width:60}).to_s
        out << "\n\n"
      end

      if !diffs[:extra].empty?
        extra_items = diffs[:extra].map do |n,q|
          [n[0..35], q]
        end
        out << Terminal::Table.new(title: "Extra (not in rawbotz)",
          headings: ['Product', 'In Cart'],
          rows:     extra_items,
          style:    {width:60}).to_s
      end

      out
    end
  end
end
