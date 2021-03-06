#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WorkPackage, 'rebuilding nested set', type: :model do
  let(:project) { FactoryGirl.create(:valid_project) }
  let(:status) { FactoryGirl.create(:status) }
  let(:priority) { FactoryGirl.create(:priority) }
  let(:type) { project.types.first }
  let(:author) { FactoryGirl.create(:user) }

  def issue_factory(parent = nil)
    FactoryGirl.create(:work_package, status: status,
                                      project: project,
                                      priority: priority,
                                      author: author,
                                      type: type,
                                      parent: parent)
  end

  let(:root_1) { issue_factory }
  let(:root_2) { issue_factory }
  let(:child_1_1) { issue_factory(root_1) }
  let(:child_1_2) { issue_factory(root_1) }
  let(:child_2_1) { issue_factory(root_2) }
  let(:gchild_1_1_1) { issue_factory(child_1_1) }
  let(:ggchild_1_1_1_1) { issue_factory(gchild_1_1_1) }
  let(:gchild_1_1_2) { issue_factory(child_1_1) }
  let(:gchild_1_2_1) { issue_factory(child_1_2) }
  let(:gchild_2_1_1) { issue_factory(child_2_1) }

  describe :valid? do
    describe 'WITH one root issue' do
      before do
        root_1
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe 'WITH two one node trees' do
      before do
        root_1
        root_2
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe 'WITH a two issue deep tree' do
      before do
        child_1_1
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe 'WITH a three issue deep tree' do
      before do
        gchild_1_1_1
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a two issue deep tree
              WITH the left value of the child beeing invalid" do

      before do
        WorkPackage.update_all({ lft: root_1.lft }, { id: child_1_1.id })
      end

      it { expect(WorkPackage).not_to be_valid }
    end

    describe "WITH a two issue deep tree
              WITH the right value of the child beeing invalid" do

      before do
        WorkPackage.update_all({ rgt: 18 }, { id: child_1_1.id })
      end

      it { expect(WorkPackage).not_to be_valid }
    end

    describe "WITH a two issue deep tree
              WITH the root_id of the child pointing to itself" do

      before do
        WorkPackage.update_all({ root_id: child_1_1.id }, { id: child_1_1.id })
      end

      it { expect(WorkPackage).not_to be_valid }
    end

    describe "WITH a three issue deep tree
              WITH the root_id of the grand child pointing to the child" do

      before do
        WorkPackage.update_all({ root_id: child_1_1.id }, { id: gchild_1_1_1.id })
      end

      it { expect(WorkPackage).not_to be_valid }
    end
  end

  describe :rebuild! do

    describe "WITH a two issues deep tree
              WITH the left value of the child beeing invalid" do

      before do
        WorkPackage.update_all({ lft: root_1.lft }, { id: child_1_1.id })

        WorkPackage.rebuild!
      end

      it { expect(WorkPackage).to be_valid }
    end
  end

  describe :rebuild_silently! do

    describe "WITH a two issues deep tree
              WITH the left value of the child beeing invalid" do

      before do
        WorkPackage.update_all({ lft: root_1.lft }, { id: child_1_1.id })

        WorkPackage.rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a two issues deep tree
              WITH the left value of the root beeing invalid
              WITH an estimated_hours values set for the root after the tree got broken" do

      before do
        WorkPackage.update_all({ lft: child_1_1.lft }, { id: root_1.id })
        WorkPackage.update_all({ estimated_hours: 1.0 }, { id: root_1.id })

        WorkPackage.rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a two issues deep tree
              WITH the right value of the root beeing invalid
              WITH an estimated_hours values set for the root after the tree got broken" do

      before do
        WorkPackage.update_all({ rgt: child_1_1.lft }, { id: root_1.id })
        WorkPackage.update_all({ estimated_hours: 1.0 }, { id: root_1.id })

        WorkPackage.rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a two issues deep tree
              WITH the root_id value of the child pointing to itself" do

      before do
        WorkPackage.update_all({ root_id: child_1_1.id }, { id: child_1_1.id })

        WorkPackage.rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a three issues deep tree
              WITH the root_id value of the grandchild pointing to itself" do

      before do
        WorkPackage.update_all({ root_id: gchild_1_1_1.id }, { id: gchild_1_1_1.id })

        WorkPackage.rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a three issues deep tree
              WITH the root_id value of the grandchild pointing to the child" do

      before do
        WorkPackage.update_all({ root_id: child_1_1.id }, { id: gchild_1_1_1.id })

        WorkPackage.rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH two three issues deep trees
              WITH the root_id value of each grandchildren pointing to the children
              WITH selecting to fix only one tree" do

      before do
        gchild_1_1_1
        gchild_2_1_1
        WorkPackage.update_all({ root_id: child_1_1.id }, { id: gchild_1_1_1.id })
        WorkPackage.update_all({ root_id: child_2_1.id }, { id: gchild_2_1_1.id })

        WorkPackage.rebuild_silently!(root_1)
      end

      it { expect(gchild_1_1_1.reload.root_id).to eq(root_1.id) }
      it { expect(gchild_2_1_1.reload.root_id).to eq(child_2_1.id) }
    end

    describe "WITH two three issues deep trees
              WITH the right value of each grandchildren being equal to the left value
              WITH selecting to fix only one tree" do

      before do
        gchild_1_1_1
        gchild_2_1_1
        WorkPackage.update_all({ rgt: gchild_1_1_1.lft }, { id: gchild_1_1_1.id })
        WorkPackage.update_all({ rgt: gchild_2_1_1.lft }, { id: gchild_2_1_1.id })

        WorkPackage.rebuild_silently!(root_1)
      end

      it { expect(gchild_1_1_1.reload.rgt).to eq(gchild_1_1_1.lft + 1) }
      it { expect(gchild_2_1_1.reload.rgt).to eq(gchild_2_1_1.lft) }
    end
  end

  describe :selectively_rebuild_silently! do

    describe "WITH a two issues deep tree
              WITH the left value of the child beeing invalid" do

      before do
        WorkPackage.update_all({ lft: root_1.lft }, { id: child_1_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a two issues deep tree
              WITH the left value of the root beeing invalid
              WITH an estimated_hours values set for the root after the tree got broken" do

      before do
        WorkPackage.update_all({ lft: child_1_1.lft }, { id: root_1.id })
        WorkPackage.update_all({ estimated_hours: 1.0 }, { id: root_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a two issues deep tree
              WITH the right value of the root beeing invalid
              WITH an estimated_hours values set for the root after the tree got broken" do

      before do
        WorkPackage.update_all({ rgt: child_1_1.lft }, { id: root_1.id })
        WorkPackage.update_all({ estimated_hours: 1.0 }, { id: root_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a two issues deep tree
              WITH the root_id value of the child pointing to itself" do

      before do
        WorkPackage.update_all({ root_id: child_1_1.id }, { id: child_1_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a three issues deep tree
              WITH the root_id value of the grandchild pointing to itself" do

      before do
        WorkPackage.update_all({ root_id: gchild_1_1_1.id }, { id: gchild_1_1_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a three issues deep tree
              WITH the root_id value of the grandchild pointing to the child" do

      before do
        WorkPackage.update_all({ root_id: child_1_1.id }, { id: gchild_1_1_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a one issue deep tree
              WITH the root_id beeing null" do
      before do
        root_1

        WorkPackage.update_all({ root_id: nil }, { id: root_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH two one issue deep trees
              WITH the root_id beeing of one pointing to the other" do
      before do
        root_1
        root_2

        WorkPackage.update_all({ root_id: root_2.id }, { id: root_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a two issue deep tree
              WITH the root_id of the child pointing to itself" do
      before do
        child_1_1

        WorkPackage.update_all({ root_id: child_1_1.id }, { id: child_1_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a tree issue deep tree
              WITH the root_id of the child pointing to another tree
              WITH the root_id of the grandchild pointing to the same other tree" do
      before do
        gchild_1_1_1

        WorkPackage.update_all({ root_id: 0 }, { id: child_1_1.id })
        WorkPackage.update_all({ root_id: 0 }, { id: gchild_1_1_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a two issue deep tree
              WITH a one issue deep tree
              WITH the root_id of the child pointing to the other tree" do
      before do
        child_1_1
        root_2

        WorkPackage.update_all({ root_id: root_2.id }, { id: child_1_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a one issue deep tree
              WITH right > left" do

      before do
        WorkPackage.update_all({ lft: 2, rgt: 1 }, { id: root_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a two issues deep tree
              WITH everything ok" do

      before do
        child_1_1

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a two issues deep tree
              WITH the child's right > left" do

      before do
        WorkPackage.update_all({ lft: 4, rgt: 3 }, { id: child_1_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a two issues deep tree
              WITH the child's right = left" do

      before do
        WorkPackage.update_all({ lft: 3, rgt: 3 }, { id: child_1_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a two issues deep tree
              WITH the child's right beeing null" do

      before do
        WorkPackage.update_all({ rgt: nil }, { id: child_1_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a two issues deep tree
              WITH the child's left beeing null" do

      before do
        WorkPackage.update_all({ lft: nil }, { id: child_1_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a two issues deep tree
              WITH the child's right beeing equal to the root's right" do

      before do
        child_1_1
        WorkPackage.update_all({ rgt: root_1.reload.rgt }, { id: child_1_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a two issues deep tree
              WITH the child's right beeing larger than the root's right" do

      before do
        child_1_1
        WorkPackage.update_all({ rgt: root_1.reload.rgt + 1 }, { id: child_1_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a two issues deep tree
              WITH the child's left beeing equal to the root's left" do

      before do
        child_1_1
        WorkPackage.update_all({ lft: root_1.reload.lft }, { id: child_1_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a two issues deep tree
              WITH the child's left beeing less than the root's right" do

      before do
        child_1_1
        WorkPackage.update_all({ rgt: root_1.reload.lft - 1 }, { id: child_1_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a two issues deep tree
              WITH the child's left beeing equal to the root's left" do

      before do
        child_1_1
        WorkPackage.update_all({ lft: root_1.reload.lft }, { id: child_1_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a two issues deep tree
               WITH the child's right beeing equal to the root's right" do

      before do
        child_1_1
        WorkPackage.update_all({ rgt: root_1.reload.rgt }, { id: child_1_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH a three issues deep tree
              WITH the child's right beeing equal to the grandchild's right" do

      before do
        gchild_1_1_1
        WorkPackage.update_all({ rgt: gchild_1_1_1.reload.rgt }, { id: child_1_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH two one issues deep tree
              WITH the two trees in the same scope (should not happen for issues)
              WITH the left of the one being the right of the other" do

      before do
        root_1
        root_2

        WorkPackage.update_all({ lft: root_1.lft, root_id: root_1.id }, { id: root_2.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH two one issues deep tree
              WITH the two trees in the same scope (should not happen for issues)
              WITH the right of the one being the lft of the other" do

      before do
        root_1
        root_2

        WorkPackage.update_all({ rgt: root_2.lft, root_id: root_2.id }, { id: root_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH one one issue deep tree
              WITH one two issues deep tree
              WITH the two trees in the same scope (should not happen for issues)
              WITH the left of the one between left and right of the other" do

      before do
        child_1_1
        root_2

        WorkPackage.update_all({ lft: child_1_1.lft, root_id: root_1.id }, { id: root_2.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end

    describe "WITH one one issue deep tree
              WITH one two issues deep tree
              WITH the two trees in the same scope (should not happen for issues)
              WITH the right of the one between left and right of the other" do

      before do
        root_1
        child_2_1

        WorkPackage.update_all({ rgt: child_2_1.rgt, root_id: root_2.id }, { id: root_1.id })

        WorkPackage.selectively_rebuild_silently!
      end

      it { expect(WorkPackage).to be_valid }
    end
  end

  describe :invalid_left_and_rights do
    describe "WITH a one issue deep tree
              WITH right > left" do

      before do
        WorkPackage.update_all({ lft: 2, rgt: 1 }, { id: root_1.id })
      end

      it { expect(WorkPackage.invalid_left_and_rights.map(&:id)).to match_array([root_1.id]) }
    end

    describe "WITH a two issues deep tree
              WITH everything ok" do

      before do
        child_1_1
      end

      it { expect(WorkPackage.invalid_left_and_rights.map(&:id)).to match_array([]) }
    end

    describe "WITH a two issues deep tree
              WITH the child's right > left" do

      before do
        WorkPackage.update_all({ lft: 4, rgt: 3 }, { id: child_1_1.id })
      end

      it { expect(WorkPackage.invalid_left_and_rights.map(&:id)).to match_array([child_1_1.id]) }
    end

    describe "WITH a two issues deep tree
              WITH the child's right = left" do

      before do
        WorkPackage.update_all({ lft: 3, rgt: 3 }, { id: child_1_1.id })
      end

      it { expect(WorkPackage.invalid_left_and_rights.map(&:id)).to match_array([child_1_1.id]) }
    end

    describe "WITH a two issues deep tree
              WITH the child's right beeing null" do

      before do
        WorkPackage.update_all({ rgt: nil }, { id: child_1_1.id })
      end

      it { expect(WorkPackage.invalid_left_and_rights.map(&:id)).to match_array([child_1_1.id]) }
    end

    describe "WITH a two issues deep tree
              WITH the child's left beeing null" do

      before do
        WorkPackage.update_all({ lft: nil }, { id: child_1_1.id })
      end

      it { expect(WorkPackage.invalid_left_and_rights.map(&:id)).to match_array([child_1_1.id]) }
    end

    describe "WITH a two issues deep tree
              WITH the child's right beeing equal to the root's right" do

      before do
        child_1_1
        WorkPackage.update_all({ rgt: root_1.reload.rgt }, { id: child_1_1.id })
      end

      it { expect(WorkPackage.invalid_left_and_rights.map(&:id)).to match_array([child_1_1.id]) }
    end

    describe "WITH a two issues deep tree
              WITH the child's right beeing larger than the root's right" do

      before do
        child_1_1
        WorkPackage.update_all({ rgt: root_1.reload.rgt + 1 }, { id: child_1_1.id })
      end

      it { expect(WorkPackage.invalid_left_and_rights.map(&:id)).to match_array([child_1_1.id]) }
    end

    describe "WITH a two issues deep tree
              WITH the child's left beeing equal to the root's left" do

      before do
        child_1_1
        WorkPackage.update_all({ lft: root_1.reload.lft }, { id: child_1_1.id })
      end

      it { expect(WorkPackage.invalid_left_and_rights.map(&:id)).to match_array([child_1_1.id]) }
    end

    describe "WITH a two issues deep tree
              WITH the child's left beeing less than the root's right" do

      before do
        child_1_1
        WorkPackage.update_all({ rgt: root_1.reload.lft - 1 }, { id: child_1_1.id })
      end

      it { expect(WorkPackage.invalid_left_and_rights.map(&:id)).to match_array([child_1_1.id]) }
    end
  end

  describe :invalid_duplicates_in_columns do
    describe "WITH a two issues deep tree
              WITH the child's left beeing equal to the root's left" do

      before do
        child_1_1
        WorkPackage.update_all({ lft: root_1.reload.lft }, { id: child_1_1.id })
      end

      it { expect(WorkPackage.invalid_duplicates_in_columns.map(&:id)).to match_array([root_1.id, child_1_1.id]) }
    end

    describe "WITH a two issues deep tree
               WITH the child's right beeing equal to the root's right" do

      before do
        child_1_1
        WorkPackage.update_all({ rgt: root_1.reload.rgt }, { id: child_1_1.id })
      end

      it { expect(WorkPackage.invalid_duplicates_in_columns.map(&:id)).to match_array([root_1.id, child_1_1.id]) }
    end

    describe "WITH two one issue deep tree
              WITH everything ok" do

      before do
        root_1
        root_2
      end

      it { expect(WorkPackage.invalid_duplicates_in_columns.map(&:id)).to match_array([]) }
    end

    describe "WITH a three issues deep tree
              WITH the child's right beeing equal to the grandchild's right" do

      before do
        gchild_1_1_1
        WorkPackage.update_all({ rgt: gchild_1_1_1.reload.rgt }, { id: child_1_1.id })
      end

      it { expect(WorkPackage.invalid_duplicates_in_columns.map(&:id)).to match_array([child_1_1.id, gchild_1_1_1.id]) }
    end
  end

  describe :invalid_roots do
    describe "WITH two one issues deep tree
              WITH everything ok" do

      before do
        root_1
        root_2
      end

      it { expect(WorkPackage.invalid_roots).to be_empty }
    end

    describe "WITH two one issues deep tree
              WITH the two trees in the same scope (should not happen for issues)
              WITH the left of the one being the right of the other" do

      before do
        root_1
        root_2

        WorkPackage.update_all({ lft: root_1.lft, root_id: root_1.id }, { id: root_2.id })
      end

      it { expect(WorkPackage.invalid_roots.map(&:id)).to match_array([root_1.id, root_2.id]) }
    end

    describe "WITH two one issues deep tree
              WITH the two trees in the same scope (should not happen for issues)
              WITH the right of the one being the lft of the other" do

      before do
        root_1
        root_2

        WorkPackage.update_all({ rgt: root_2.lft, root_id: root_2.id }, { id: root_1.id })
      end

      it { expect(WorkPackage.invalid_roots.map(&:id)).to match_array([root_1.id, root_2.id]) }
    end

    describe "WITH one one issue deep tree
              WITH one two issues deep tree
              WITH the two trees in the same scope (should not happen for issues)
              WITH the left of the one between left and right of the other" do

      before do
        child_1_1
        root_2

        WorkPackage.update_all({ lft: child_1_1.lft, root_id: root_1.id }, { id: root_2.id })
      end

      it { expect(WorkPackage.invalid_roots.map(&:id)).to match_array([root_1.id, root_2.id]) }
    end

    describe "WITH one one issue deep tree
              WITH one two issues deep tree
              WITH the two trees in the same scope (should not happen for issues)
              WITH the right of the one between left and right of the other" do

      before do
        root_1
        child_2_1

        WorkPackage.update_all({ rgt: child_2_1.rgt, root_id: root_2.id }, { id: root_1.id })
      end

      it { expect(WorkPackage.invalid_roots.map(&:id)).to match_array([root_1.id, root_2.id]) }
    end
  end

  describe :invalid_root_ids do
    describe "WITH a one issue deep tree
              WITH everything ok" do
      before do
        root_1
      end

      it { expect(WorkPackage.invalid_root_ids).to be_empty }
    end

    describe "WITH a two issue deep tree
              WITH everything ok" do
      before do
        child_1_1
      end

      it { expect(WorkPackage.invalid_root_ids).to be_empty }
    end

    describe "WITH a three issue deep tree
              WITH everything ok" do
      before do
        gchild_1_1_1
      end

      it { expect(WorkPackage.invalid_root_ids).to be_empty }
    end

    describe "WITH a one issue deep tree
              WITH the root_id beeing null" do
      before do
        root_1

        WorkPackage.update_all({ root_id: nil }, { id: root_1.id })
      end

      it { expect(WorkPackage.invalid_root_ids).to be_empty }
    end

    describe "WITH two one issue deep trees
              WITH the root_id beeing of one pointing to the other" do
      before do
        root_1
        root_2

        WorkPackage.update_all({ root_id: root_2.id }, { id: root_1.id })
      end

      it { expect(WorkPackage.invalid_root_ids.map(&:id)).to match_array([root_1.id]) }
    end

    describe "WITH a two issue deep tree
              WITH the root_id of the child pointing to itself" do
      before do
        child_1_1

        WorkPackage.update_all({ root_id: child_1_1.id }, { id: child_1_1.id })
      end

      it { expect(WorkPackage.invalid_root_ids.map(&:id)).to match_array([child_1_1.id]) }
    end

    describe "WITH a two issue deep tree
              WITH a one issue deep tree
              WITH the root_id of the child pointing to the other tree" do
      before do
        child_1_1
        root_2

        WorkPackage.update_all({ root_id: root_2.id }, { id: child_1_1.id })
      end

      it { expect(WorkPackage.invalid_root_ids.map(&:id)).to match_array([child_1_1.id]) }
    end

    describe "WITH a three issue deep tree
              WITH the root_id of the child pointing to another tree
              WITH the root_id of the grandchild pointing to the same other tree" do
      before do
        gchild_1_1_1

        WorkPackage.update_all({ root_id: 0 }, { id: child_1_1.id })
        WorkPackage.update_all({ root_id: 0 }, { id: gchild_1_1_1.id })
      end

      # As the sql statements do not work recursively
      # we are currently only able to spot the child
      # this is not how it should be
      it { expect(WorkPackage.invalid_root_ids.map(&:id)).to match_array([child_1_1.id]) }
    end
  end
end
