package RebuildParentCategories::Plugin;

use strict;

sub _rebuild_parent_categories {
    my ( $cb, $app, $entry, $original ) = @_;
    if ( $entry->class ne 'entry' ) {
        return 1;
    }
    require MT::Entry;
    my $rebuild;
    my @old_categories;
    if ( $entry->status == MT::Entry::RELEASE() ) {
        $rebuild = 1;
    }
    if ( defined ( $original ) ) {
        if ( $original->status != $entry->status ) {
            if ( ( $original->status == MT::Entry::RELEASE() ) ||
                ( $entry->status == MT::Entry::RELEASE() ) ) {
                $rebuild = 1;
            }
        }
        my $entry_cats = $entry->categories;
        my $orig_cats = $original->categories;
        if ( @$orig_cats ) {
            my @category_ids;
            for my $cat ( @$entry_cats ) {
                push ( @category_ids, $cat->id );
            }
            for my $old ( @$orig_cats ) {
                my $old_id = $old->id;
                if (! grep( /^$old_id$/, @category_ids ) ) {
                    push ( @old_categories, $old );
                    $rebuild = 1;
                }
            }
        }
    }
    if ( $rebuild ) {
        require MT::WeblogPublisher;
        require MT::FileInfo;
        my $blog = $entry->blog;
        my $pub = MT::WeblogPublisher->new;
        my @published_category_id;
        my $entry_categories = $entry->categories;
        push ( @$entry_categories, @old_categories );
        for my $cat ( @$entry_categories )  {
            next if (! $cat );
            for my $parent ( $cat->parent_categories ) {
                my $parent_id = $parent->id;
                next if ( grep( /^$parent_id$/, @published_category_id ) );
                push ( @published_category_id, $parent_id );
                next if (! $parent );
                my @fis = MT::FileInfo->load( {
                                               blog_id => $blog->id,
                                               archive_type => 'Category',
                                               category_id => $parent_id,
                                             }, );
                if ( @fis ) {
                    for my $fi ( @fis ) {
                        my $res = $pub->rebuild_from_fileinfo( $fi );
                    }
                }
            }
        }
    }
    return 1;
}

1;